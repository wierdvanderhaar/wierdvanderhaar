for file in Ch*; do 
   new=`echo $file| cut -f 1 -d ' ' `
   echo "mv '$file' $new"
done
