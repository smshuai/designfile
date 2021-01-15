// Re-usable componext for adding a helpful help message in our Nextflow script
def helpMessage() {
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --step collect --glob '**/results/**/bin/LP*' --s3_location  's3://lifebit-featured-datasets/IGV/' --output_file design_file.csv
    nextflow run main.nf --step stage  --desgin design_file.csv
    Mandatory arguments:


    """.stripIndent()
}

if (params.step == 'collect') {
    
    if (!params.output_file.endsWith('csv')) exit 1, "You have specified the --output_file to be '${params.output_file}', which does not indicate a comma sepearated file.\nPlease specify an output file name with --output_file that ends with .csv"

    Channel.fromPath("${params.s3_location}/${params.glob}")
       .map { it -> [ file(it).baseName, "s3:/"+it] }
       .groupTuple(by:0)
       .set { ch_files }

    process create_design_row {
    tag "file:${name}"

    input:
    set val(name), val(s3_file) from ch_files

    output:
    file "${name}.csv" into ch_rows

    """
    # ! Only the first file is used for samples with multiple files
    echo "${name},${s3_file.collect {"$it"}[0]}" > ${name}.csv
    cat ${name}.csv
    """
    }

    process bind_design_rows {
    publishDir 'results/s3_locations/', mode: 'copy'

    input:
    file(design_rows) from ch_rows.collect()

    output:  
    file("${params.output_file}") into ch_design_file

    """
    echo "name,file" > header.csv
    for row in $design_rows; do cat \$row >> body.csv; done
    cat header.csv body.csv > ${params.output_file}
    """
    }
}

if (params.step == 'stage') {
    if (params.design) {
        Channel.fromPath(params.design)
            .splitCsv(sep: ',', skip: 1)
            .map { name, file -> file(file) }
            .collect()
            .set { ch_files }
    }

    process stage_bins {
        publishDir "results/"
        echo true

        input:
            path files from ch_files
      
        output:
            path 'file/'
      
        shell:
        '''
        ls ./ > all_files
        mkdir -p file
        cat ./all_files | while read f
        do
            mv $f file/
        done
        rm file/all_files
        '''
    }
}
