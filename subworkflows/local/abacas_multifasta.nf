//
// Process multiple multifasta files with abacas
//
include { ABACAS        } from '../../modules/nf-core/abacas/main'
include { SEQKIT_SPLIT  } from '../../modules/local/seqkit_split'
include { SEQKIT_CONCAT } from '../../modules/nf-core/seqkit/concat/main'

workflow ABACAS_MULTI {
    take:
    scaffold   // channel: [ val(meta), path(scaffold) ]
    multifasta // channel: /path/to/genome.fasta

    main:

    ch_versions = Channel.empty()

    //
    // Split multifasta file into individual fasta files
    //
    SEQKIT_SPLIT (
        multifasta.map { [ [:], it ] }
    )
    ch_fasta_list = SEQKIT_SPLIT.out.fastx
    ch_versions = ch_versions.mix(SEQKIT_SPLIT.out.versions)

    //
    // Run abacas on each fasta file
    //
    ch_abacas = Channel.empty()
    ch_fasta_list
        .transpose()
        .map { meta, fasta -> fasta }
        .set { ch_fasta}

    scaffold
        .combine (ch_fasta)
        .set { ch_scaffold_fasta }

    ABACAS (
        ch_scaffold_fasta.map { meta, scaffold, fasta -> tuple( meta, scaffold ) },
        ch_scaffold_fasta.map { meta, scaffold, fasta -> fasta }
    )
    ch_abacas = ABACAS.out.results
    ch_versions = ch_versions.mix(ABACAS.out.versions)

    //
    // Concatenate abacas results
    //

    ch_abacas
        .map { meta, files -> tuple(meta, files[3]) }
        .groupTuple()
        .map { meta, files -> tuple(meta, files.flatten()) }
        .set{ ch_abacas }

    SEQKIT_CONCAT (
        ch_abacas
    )

    emit:
    abacas_results     = SEQKIT_CONCAT.out.fastx
    versions           = ch_versions           // channel: [ versions.yml ]
}
