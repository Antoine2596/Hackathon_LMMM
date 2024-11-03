
mkdir -p trimming

for file in mini_data/*gz ; do
        filename=$(basename "$file" ".fastq.gz")
        echo "$filename"
	singularity exec cutadapt_v1.11.sif cutadapt -a file:fastqc/formated_ADAPTERS.fasta -o trimming/"$filename".fastq.gz  mini_data/"$filename".fastq.gz
done
