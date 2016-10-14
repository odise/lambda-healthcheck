dependencies:
	#pip install aws-requests-auth -t ./src
	pip install requests -t ./src

clean:
	rm -f lambda_function_payload.zip
	
build:
	cd src && zip -r ../lambda_function_payload.zip *

plan:
	terraform plan

apply:
	terraform apply
