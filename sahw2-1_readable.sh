ls -lAR | awk '
BEGIN{
    count_dir = 0;
    count_file = 0;
    count_size = 0
}
/^d/{count_dir++}
/^-/{
    size[count_file] = $5;
    name[count_file++] = $9;
    count_size += $5
}
END{
    for(i=0;i<(5<count_file?5:count_file);i++){
	big = 0;
    	for(j=0;j<count_file;j++)if(size[j] > size[big])big = j;
	print i+1 ":" size[big],name[big];
	size[big] = 0
    }
    print "Dir num:",count_dir "\nFile num:",count_file "\nTotal:",count_size
}
'
