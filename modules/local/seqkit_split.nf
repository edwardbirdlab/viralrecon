process SEQKIT_SPLIT {
    tag "$fastx.baseName"
    label 'process_low'

    conda "bioconda::seqkit=2.9.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.9.0--h9ee0642_0':
        'biocontainers/seqkit:2.9.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(fastx)

    output:
    tuple val(meta), path("${fastx.baseName}*/*.{fasta,fastq,fa,fq,fas,fna,faa}")    , emit: fastx
    path "versions.yml"                                                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def extension   = "fastq"
    if ("$fastx" ==~ /.+\.fasta|.+\.fasta.gz|.+\.fa|.+\.fa.gz|.+\.fas|.+\.fas.gz|.+\.fna|.+\.fna.gz|.+\.fsa|.+\.fsa.gz/ ) {
        extension   = "fasta"
    }

    """
    seqkit \\
        split \\
        --threads $task.cpus \\
        $args \\
        $fastx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version | cut -d' ' -f2)
    END_VERSIONS
    """
}
