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
awk -v OFS="\t" '{ print $1, $2, $3, "DEL", $4 }' ${WRKDIR}/final_variants/${COHORT_ID}.deletion.bed | fgrep -v "#" > ${WRKDIR}/annotations/deletion_preAnno.bed
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/geneAnnotation.log -e ${OUTDIR}/logs/geneAnnotation.log -u nobody -J ${COHORT_ID}_annotation "${liWGS_SV}/scripts/annotate_SVintervals.sh ${WRKDIR}/annotations/deletion_preAnno.bed DEL ${WRKDIR}/annotations/deletion_gene_anno.bed ${params}"

#Submit duplication annotation
awk -v OFS="\t" '{ print $1, $2, $3, "DUP", $4 }' ${WRKDIR}/final_variants/${COHORT_ID}.duplication.bed | fgrep -v "#" > ${WRKDIR}/annotations/duplication_preAnno.bed
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/geneAnnotation.log -e ${OUTDIR}/logs/geneAnnotation.log -u nobody -J ${COHORT_ID}_annotation "${liWGS_SV}/scripts/annotate_SVintervals.sh ${WRKDIR}/annotations/duplication_preAnno.bed DUP ${WRKDIR}/annotations/duplication_gene_anno.bed ${params}"

#Submit inversion annotation (averages cluster coordinates for breakpoints in BED)
awk -v OFS="\t" '{ printf "%s\t%.0f\t%.0f\t%s\t%s\n", $1, ($2+$5)/2, ($3+$6)/2, "INV", $7 }' ${WRKDIR}/final_variants/${COHORT_ID}.inversion.bedpe | fgrep -v "#" > ${WRKDIR}/annotations/inversion_preAnno.bed
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/geneAnnotation.log -e ${OUTDIR}/logs/geneAnnotation.log -u nobody -J ${COHORT_ID}_annotation "${liWGS_SV}/scripts/annotate_SVintervals.sh ${WRKDIR}/annotations/inversion_preAnno.bed INV ${WRKDIR}/annotations/inversion_gene_anno.bed ${params}"

#Submit insertion source annotation
awk -v OFS="\t" '{ print $1, $2, $3, "INS_SOURCE", $7 }' ${WRKDIR}/final_variants/${COHORT_ID}.insertion.bedpe | fgrep -v "#" > ${WRKDIR}/annotations/insertionSource_preAnno.bed
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/geneAnnotation.log -e ${OUTDIR}/logs/geneAnnotation.log -u nobody -J ${COHORT_ID}_annotation "${liWGS_SV}/scripts/annotate_SVintervals.sh ${WRKDIR}/annotations/insertionSource_preAnno.bed INS_SOURCE ${WRKDIR}/annotations/insertionSource_gene_anno.bed ${params}"

#Submit insertion sink annotation
awk -v OFS="\t" '{ print $4, $5, $6, "INS_SINK", $7 }' ${WRKDIR}/final_variants/${COHORT_ID}.insertion.bedpe | fgrep -v "#" | sed '1d' > ${WRKDIR}/annotations/insertionSink_preAnno.bed
bsub -q normal -sla miket_sc -o ${OUTDIR}/logs/geneAnnotation.log -e ${OUTDIR}/logs/geneAnnotation.log -u nobody -J ${COHORT_ID}_annotation "${liWGS_SV}/scripts/annotate_SVintervals.sh ${WRKDIR}/annotations/insertionSink_preAnno.bed INS_SINK ${WRKDIR}/annotations/insertionSink_gene_anno.bed ${params}"