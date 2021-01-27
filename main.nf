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
            .map { name, main_file -> [ name, file(main_file) ] }
            .set { ch_main_files }
    }

    process stage_main_files {
    tag "id:${name}"
    publishDir "results/staged/", pattern: "files/*"
    maxForks 60

    input:
    set val(name), file(file_path) from ch_main_files

    output:
    file("md5sums/${name}_md5sum.txt") into ch_md5sum
    file("files/${name}")

    script:
    """
    mkdir -p md5sums
    mkdir -p files
    md5sum ${name} > md5sums/"${name}"_md5sum.txt
    mv ${name} ./files/
    sleep 600
    """
    }

    process collect_checksums {
    tag "id:${name}"
    publishDir "results/staged/"

    input:
    file(checksums) from ch_md5sum.collect()

    output:
    file("all_checksums.txt")

    script:
    """
    cat *txt > all_checksums.txt
    """
    }
}
