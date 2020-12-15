# lifebit-ai/designfile

Minimal Nextflow workflow that collects the paths from an S3 location (bucket, folder of bucket) into a design file to be used for subsequent workflows


## Usage

Typical usage:

```bash
nextflow run main.nf --s3_location  's3://lifebit-featured-datasets/IGV/' --file_suffix 'cram' --index_suffix 'crai'
```

### Parameters

#### `--s3_location`

The S3 location of the bucket or a folder of the bucket. For example `'s3://lifebit-featured-datasets/IGV/'`.

#### `--file_suffix`

The file suffix, default: `'cram'`.

#### `--index_suffix`

The file index suffix, default: `'crai'`.

#### `--output_file`

The name of the output file to write the design file with the columns:
- name
- file
- index

For example `design.csv`. It must have a ".csv" suffix, or else the pipeline will stop with an error similar to the following:

```console
You have specified the --output_file to be 'this.txt', which does not indicate a comma sepearated file.
Please specify an output file name with --output_file that ends with .csv
```
## Output

The output file is expected to look like this:

```csv
# contents of design.csv file

name,file,index
SARS-COV2_pass,s3://lifebit-featured-datasets/IGV/cram/SARS-COV2_pass.minimap2.sorted.cram,s3://lifebit-featured-datasets/IGV/cram/SARS-COV2_pass.minimap2.sorted.cram.crai
HG002_ONT,s3://lifebit-featured-datasets/IGV/samplot/HG002_ONT.cram,s3://lifebit-featured-datasets/IGV/samplot/HG002_ONT.cram.crai
```
