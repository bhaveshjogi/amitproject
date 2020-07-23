#current commit to fetch from git log
python3 update_sfdx_json.py
CURRENT_COMMIT=$(git log --format="%H" -n 1)

WSPACE=$(pwd)

# Filename to add logs of this script
LOGFILENAME=$WSPACE/delta.log


# make a directory to keep previous successful build commit file
#mkdir -p $WSPACE/build/gitCommit/
#touch $WSPACE/build/gitcommit/githash.txt 
echo $2 > Jenkins/githash.txt
cat Jenkins/githash.txt
BRANCH=$1
# CIRCLE_BRANCH="develop"
#echo "downloading previouscommit file from s3 bucket"
#aws s3 sync s3://oau-crm-salesforce-metadatabackup/gitCommit/$BRANCH/ .
#ls -l
#Previous successful build name
BNAME="githash" 
# "prevCommit"

#echo Build Name: $BNAME
echo Workspace: $WSPACE

#create a folder in current workspace to copy changed files
if [[ ! -d "$WSPACE/target" ]]
                then
                        echo "create target directory"
                        mkdir $WSPACE/target
                else 
                        echo "remove dummy file"
                        rm -rf $WSPACE/target/*
                fi

echo Current Commit: $CURRENT_COMMIT
COMMITFILE='Jenkins/'$BNAME'.txt'
echo COMMITFILE is $COMMITFILE
echo Searching for last successful commit file $COMMITFILE...
# check if previous commit exists. If not then whole code will get deployed
if [ -e $COMMITFILE ]
then
        # get previous build's RSA
        PREVRSA=$(<$COMMITFILE) &&
        echo Found previous SHA $PREVRSA
        # chack if changed files has any build files in it i.e. changes in force-app folder
        if [[ `git diff-tree --no-commit-id --name-only -r $CURRENT_COMMIT $PREVRSA | grep force-app | wc -l` > 0 ]] 
        then         
                echo "below are changed file from previos commit $PREVRSA to the lates commit $CURRENT_COMMIT :" >> $LOGFILENAME
                # Store all the changed files in a text file to read in a while loop one by one 
                git diff-tree --no-commit-id --name-only -r $CURRENT_COMMIT $PREVRSA | grep force-app | awk '{ print $0 }' >> $WSPACE/getDiff.txt

                git diff-tree --no-commit-id --name-only -r $CURRENT_COMMIT $PREVRSA | grep force-app >> $LOGFILENAME
                echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $LOGFILENAME
                echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $LOGFILENAME

               #read file names one by one from the changed files
                while read CFILE
                do
                        echo Analyzing file `basename "$CFILE"` >> $LOGFILENAME
                        
                        cd ${WSPACE}/force-app/main/default

                        # set a prefix variable to remove it from file name
                        prefix="force-app/main/default/"

                        # echo changed file is "$CFILE" >> $LOGFILENAME
                        #remove prefix from the current filename

                        filename=${CFILE#"$prefix"}

                        echo file name is $filename >> $LOGFILENAME

                        # echo filename prefix is ${filename%.*} >> $LOGFILENAME

                        if [[ -f "$WSPACE/$CFILE" ]] 
                        then
                                # if there are aura or lwc components in the build, we need to get whole folder
                                if [ "$WSPACE/$CFILE" == *"aura"* ] || [ "$WSPACE/$CFILE" == *"lwc"* ]
                                then
                                        # echo "Aura exists"
                                        cp --parent "${filename%/*}"/* ${WSPACE}/target/
                                else
                                        # get all the supporting meta files along with the changed files. hence getting everything after -
                                        cp --parent "${filename%-*}"* ${WSPACE}/target/
                                fi
                        else 
                                echo filename $CFILE does not exist >> $LOGFILENAME
                                echo "------------------------------------------------------------------------------------------------" >> $LOGFILENAME
                        fi  
                # reading each file line by line 
                done < ${WSPACE}/getDiff.txt
                cd ${WSPACE}
                #convert target folder (which has changed files) into mdapi format into deployChangeCode folder
                #./build/mdapiConvert.sh ./deployChangeCode ./target
        else
                echo "no changes in code"
        fi
else
        echo No RSA found 
        cd ${WSPACE}
        cp -rp force-app/ target/
        echo "Whole code will be deployed"
        #./build/mdapiConvert.sh ./deployChangeCode ./force-app
fi
