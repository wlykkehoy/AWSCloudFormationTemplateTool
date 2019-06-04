#!/bin/bash

#=================================================================================
# This script wraps commonly used tools for developing AWS CloudFormation 
# Templates, making the code / test / create / destroy cycle easier on 
# ye 'ol fingers.
#
# NOTE: THE NAME OF THE TEMPLATE FILE, STACK NAME, AND ANY PARAMETERS ARE
# HARD-CODED. NOT GREAT PRACTICE HOWEVER THE PURPOSE OF THIS SCRIPT IS TO 
# SAVE TYPING THOSE EACH AND EVERY RUN.
#=================================================================================


#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!! TEMPLATE SPECIFIC STUFF - MODIFY PER EACH UNIQUE TEMPLATE  !!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
TEMPLATE_FILE_NAME="test0.json"
STACK_NAME="test0"
REGION="us-east-1"
#CREATE_PARAMETERS="--parameters ParameterKey=KeyName,ParameterValue=SEIS665-AWSEC2-VA ParameterKey=YourIp,ParameterValue=24.118.160.56/32"
CREATE_PARAMETERS=""
#ADDITIONAL_CREATE_ARGS="--capabilities CAPABILITY_IAM"
ADDITIONAL_CREATE_ARGS=""
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!! END OF TEMPLATE SPECIFIC STUFF !!!!!!!!!!!!!!!!!!!!!!!!!!!
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



#--------------------------------------------------------------------------------
# This function runs cf-lint on the template
#--------------------------------------------------------------------------------
function run_lint() {
	echo "lint checking template ${TEMPLATE_FILE_NAME} ..."
	cfn-lint ${TEMPLATE_FILE_NAME}
	if [[ $? = 0 ]]
	then
		echo "Yipee - it's clean!!!"
	fi
}


#--------------------------------------------------------------------------------
# This function runs AWS CloudFormation validate-template on the template 
#--------------------------------------------------------------------------------
function run_validate() {
	echo "validating template ${TEMPLATE_FILE_NAME} ..."
	aws cloudformation validate-template --region ${REGION} --template-body file://${TEMPLATE_FILE_NAME}
}


#--------------------------------------------------------------------------------
# This function creates the stack
# Note the file name (less extension) is used as the stack name
#--------------------------------------------------------------------------------
function create_stack() {
	echo "creating stack ${STACK_NAME} from template ${TEMPLATE_FILE_NAME}..."
	aws cloudformation create-stack --region ${REGION} --stack-name ${STACK_NAME} --template-body file://${TEMPLATE_FILE_NAME} ${ADDITIONAL_CREATE_ARGS} ${CREATE_PARAMETERS}
	if [[ "${1}" = "wait" ]]
	then
		echo "waiting for stack creation to complete ..."
		aws cloudformation wait stack-create-complete --region ${REGION} --stack-name ${STACK_NAME}
		echo "creation completed"
	fi
}


#--------------------------------------------------------------------------------
# This function gets the stack info
# Note the file name (less extension) is used as the stack name
#--------------------------------------------------------------------------------
function  get_info() {
	echo "getting info for stack ${STACK_NAME} ..."
	aws cloudformation describe-stacks --region ${REGION} --stack-name ${STACK_NAME}
}


#--------------------------------------------------------------------------------
# This function destroys the stack
# Note the file name (less extension) is used as the stack name
#--------------------------------------------------------------------------------
function delete_stack() {
	echo "deleting stack ${STACK_NAME} ..."
	aws cloudformation delete-stack --region ${REGION} --stack-name ${STACK_NAME} 
	if [[ "${1}" = "wait" ]]
	then
		echo "waiting for stack deletion to complete ..."
		aws cloudformation wait stack-delete-complete --region ${REGION} --stack-name ${STACK_NAME}
		echo "deletion completed"
	fi	
}


#--------------------------------------------------------------------------------
# This function merely displays usage info
#--------------------------------------------------------------------------------
function display_usage() {
    echo "Usage ${0} [-l|-v|-c|-C|-s|-d|-D] "
}


#--------------------------------------------------------------------------------
# And finally, our main body of code.
#--------------------------------------------------------------------------------

# Should have 1 user args; the action
if [[ $# -ne 1 ]]
then
	display_usage
	exit 1
fi

# First and only argument to the script is the action to take.
ACTION=${1:-no_arg}

case "${ACTION}" in
  -l|--lint)
    run_lint
    ;;
  -v|--validate)
    run_validate
    ;;
  -c|--create)
    create_stack "nowait"
    ;;
  -C|--create-and-wait)
    create_stack "wait"
    ;;	
  -i|--info)
    get_info
    ;;	
  -d|--delete)
    delete_stack "nowait"
    ;;	
  -D|--delete-and-wait)
    delete_stack "wait"
    ;;	
  *)
    echo "Unrecognized argument ${ACTION}"
	display_usage
    exit 1
    ;;
esac

exit 0

