#!/bin/bash

#liWGS-SV Pipeline: Module 9 (Variant annotation)
#August 2015
#Contact: rcollins@chgr.mgh.harvard.edu

#Read input
samples_list=$1
params=$2

#Source params file
. ${params}

#Make output directory
mkdir ${WRKDIR}/annotations

#Submit deletion annotation
awk -v OFS="\t" '{ print $1, $2, $3, "DEL", $4 }' ${WRKDIR}/${COHORT_ID}.deletion.bed > ${WRKDIR}/annotations/deletions_preAnno.bed
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/module9.log -e ${OUTDIR}/logs/module9.log -u nobody -J ${COHORT_ID}_MODULE_9_sub "${liWGS_SV}/scripts/annotate_SVintervals.sh ${WRKDIR}/annotations/deletions_preAnno.bed DEL ${WRKDIR}/annotations/deletion_gene_anno.bed ${params}"
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/module9.log -e ${OUTDIR}/logs/module9.log -u nobody -J ${COHORT_ID}_MODULE_9_sub "${liWGS_SV}/scripts/annotate_SVintervals.sh [in.bed] DUP ${WRKDIR}/annotations/duplication_gene_anno.bed ${params}"
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/module9.log -e ${OUTDIR}/logs/module9.log -u nobody -J ${COHORT_ID}_MODULE_9_sub "${liWGS_SV}/scripts/annotate_SVintervals.sh [in.bed] INV ${WRKDIR}/annotations/inversion_gene_anno.bed ${params}"
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/module9.log -e ${OUTDIR}/logs/module9.log -u nobody -J ${COHORT_ID}_MODULE_9_sub "${liWGS_SV}/scripts/annotate_SVintervals.sh [in.bed] INS_SOURCE ${WRKDIR}/annotations/insSource_gene_anno.bed ${params}"
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/module9.log -e ${OUTDIR}/logs/module9.log -u nobody -J ${COHORT_ID}_MODULE_9_sub "${liWGS_SV}/scripts/annotate_SVintervals.sh [in.bed] INS_SINK ${WRKDIR}/annotations/insSink_gene_anno.bed ${params}"
