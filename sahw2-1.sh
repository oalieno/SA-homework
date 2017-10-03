#!/bin/sh
ls -lAR | awk -v num=$1 'BEGIN{d=0;f=0;s=0}/^d/{d++}/^-/{S[f]=$5;N[f++]=$9;s+=$5}END{for(i=0;i<(num<f?num:f);i++){b=0;for(j=0;j<f;j++)if(S[j]>S[b])b=j;print i+1 ":" S[b],N[b];S[b]=0;}print "Dir num:",d "\nFile num:",f "\nTotal:",s}'
