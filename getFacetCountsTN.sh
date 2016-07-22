#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

SAMTOOLS=/opt/common/CentOS_6-dev/bin/current/samtools

if [ $# -lt "2" ]; then
    echo "usage:: getFacetCountsTN.sh NORMAL_BAM TUMOR_BAM [OUTFILE]"
    exit
fi

NBAM=$1
TBAM=$2

if [ $# -eq "3" ]; then
    OFILE=$3
else
    NSAMP=$($SAMTOOLS view -H $NBAM | fgrep "@RG" | head -1 | perl -ne 'm/SM:(\S+)/;print $1');
    TSAMP=$($SAMTOOLS view -H $TBAM | fgrep "@RG" | head -1 | perl -ne 'm/SM:(\S+)/;print $1');
    mkdir -p counts/${TSAMP}___${NSAMP}
    OFILE=counts/${TSAMP}___${NSAMP}/counts___${TSAMP}___${NSAMP}.dat
fi

echo OFILE=$OFILE

GENOME_BUILD=$($SDIR/FillOut/GenomeData/getGenomeBuildBAM.sh $TBAM)
GENOME_SH=$SDIR/FillOut/GenomeData/genomeInfo_${GENOME_BUILD}.sh
if [ ! -e "$GENOME_SH" ]; then
    echo "Unknown genome build ["${GENOME_BUILD}"]"
    exit
fi

echo "Loading genome [${GENOME_BUILD}]" $GENOME_SH
source $GENOME_SH
echo GENOME=$GENOME
echo FACETSNPS=$FACETSNPS
echo OFILE=$OFILE

bamList=_bamList_$(uuidgen)

echo $NBAM >$bamList
echo $TBAM >>$bamList

echo
echo "Calling fillOutCBE ..."

#
# fillOutCBE.sh uses 8 threads and 33 Gb for 2 BAMS
#

$SDIR/FillOut/fillOutCBE.sh -v $bamList <(zcat $FACETSNPS) ${OFILE}.vcf
$SDIR/cvtVCF2FacetsCounts.py --fragments ${OFILE}.vcf ${OFILE}

gzip -9 $OFILE
rm $bamList
rm ${OFILE}.vcf
