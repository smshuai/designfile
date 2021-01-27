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

if (params.design) {
    Channel.fromPath(params.design)
        .splitCsv(sep: ',', skip: 1)
        .map { name, main_file -> [ name, file(main_file) ] }
        .set { ch_main_files }
}

if (params.step == 'stage') {


    process stage_main_files {
    tag "id:${name}"
    publishDir "results/staged/"
    maxForks 44

    input:
    set val(name), file(file_name) from ch_main_files

    output:
    file("md5sums/${name}_md5sum.txt")
    file("files/${file_name}")

    script:
    """
    mkdir -p md5sums
    mkdir -p files
    md5sum ${file_name} > md5sums/${name}_md5sum.txt
    mv ${file_name} ./files/
    sleep 600
    """
    }
}
