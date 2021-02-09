
function validate_backup_params()
{
if (($#!=3)); then
	echo "parameter(s) missing"
	exit 1
fi

#validation of the given arguments

if [ ! -d "$1" ]; then
	echo "no directory exists with this name"
	exit 1 
fi

if [ ! -d "$2" ]; then 
	echo "no directory exists with this name"
	exit 1
fi 

#restoring the parameters into variables 
direct=$1
dest=$2
key=$3

}

function backup()
{
#saving the date
da=$(date)
da=$(date | sed s/\ /_/g | sed s/\:/_/g)

#creating new directories 
mkdir $dest/$da
mkdir $dest/files

#looping over all items in the directory from the first parameter 

for d in $direct/*
do 

	#if the item is a directory 
	if [[ -d $d ]]; then
		name="${d}_${da}"
		#zipping 
		tar -cvzf ./$name.tgz ./$d/
		#encrypting
		gpg -c --batch --passphrase "$key" $name.tgz
		rm $name.tgz
		mv $name.tgz.gpg $dest/$da
	fi

	#if the item is a file
	if [[ -f $d ]]; then
		tar -uvf ./$d.tar ./$d/
		gzip $d.tar
		mv $d.tar.gz ./$dest/files
	fi


done

#zipping the "files" directory

tar -cvzf ./files.tgz $dest/files
mv files.tgz $dest
rm -r $dest/files

#encryption
gpg -c --batch --passphrase "$key" $dest/files.tgz
rm $dest/files.tgz

}


function validate_restore_params()
{

if (($#!=3)); then
	echo " parameter(s) missing" 
	exit 1
fi

#validating the given parameters

if [ ! -d "$1" ]; then 
	echo "no directory exists with this name" 
	exit 1 
fi

if [ ! -d "$2" ]; then
	echo "no directory exists with this name" 
	exit 1
fi

#placing the parameters into variables 
src=$1
dest=$2
key=$3

}

function restore()
{
#making temp directory under the restoration directory 
mkdir $dest/temp

#loop over all items in the first parameter 
for d in $src/*
do 
	#handling the directory that contains the directories first
	if [[ -d $d ]]; then

		for f in $d/*
		do 
			echo "$f"
			#decryptings the files inside the directory
			gpg --batch --passphrase "$key" $f
			rm $f
		done

		for f in $d/*
		do 
			echo "$f"
			tar -xvzf $f --directory $dest
		done


	rm -d $d
	else
	#handling the encrypted file that contains the files
	#decrypting 
		gpg --batch --passphrase "$key" $d

		rm $d
	fi

rm -r $d
done

for f in $src/*
do
	mv $f $dest/temp
done

#decompressing the files in temp and moving them to the destination 

#moving directories to the destination directory
for f in $dest/temp/*
do
	mv $f $dest

done 

rm -d $dest/temp

#unzipping the directory containing the files
tar -xvzf $dest/files.tgz
rm  $dest/files.tgz


mv $src/files $dest

for f in $dest/files/*
do 
	tar -xzvf $f --directory $dest
done 

rm -r $dest/files

for d in $dest
do
	for s in $d/*
	do
		for n in $s/*
		do
			mv $n $dest
		done
	rm -r $s 
	done
done 
}

