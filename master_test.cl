#MASTER SCRIPT
#Erini Lambrides
#Dec 17 2013

procedure master_test(foo)

string semester
string date
string type
string subdir
string range
string foo
string obj_name     
string reduc_name   
string obj_ext      
string tellur_ext   
string flat_ext     
string arc_ext  
string objectname[100]
string reducename
string crosscorr
string home
bool object = no
bool telluric = no
bool flat = no
bool arc = no
char scitot[100]
char dirtot[100]
char rawdir[100]
int nsci
int i
struct *list1


begin



nsci=0
i=0
home="/home/elambrid/Desktop/Geballe/All"
list1 = "master_gnirs_metadata.lis"
while (fscan (list1,semester,date,type, subdir, range) !=EOF) {
	
	if (access(semester)){
		cd (semester)
		
       		if (access(date)) {
			print ("type: ", type)			
			cd ("../")
			goto nextstep
       		} else {    
				
       	        	mkdir (date)
			cd ("../")
			copy ("N"//date//"S*", semester//"/"//date)      			
			goto nextstep
		}	
	} else {   
		
		mkdir (semester)
		cd (semester)
		mkdir (date)
	      	cd ("../")	
		copy ("N"//date//"S*", semester//"/"//date)
	}	
	
	nextstep:


		if (type == "TELL"){
			tellur_ext = range
			telluric= yes
		}
		if (type == "FLAT"){
			flat_ext = range
			flat = yes
		}
		if (type == "ARC"){
			arc_ext=range
			arc = yes
		}
		if (type == "SCIENCE") {
			nsci=nsci+1
			scitot[nsci]=range
			dirtot[nsci]= subdir
			objectname[nsci]= "N"//date//"S"
			rawdir[nsci] = "/home/elambrid/Desktop/Geballe/All/"//semester//"/"//date//"/"
			print ("Yo :",rawdir[nsci])			
			cd (rawdir[nsci])
			print ("hi: ", dirtot[nsci])			
			mkdir(dirtot[nsci])
			cd ("../../")
			object = yes
			print("FOOBAR")
		}
	if (type == "FLAT" && object == yes && telluric == yes && flat == yes && arc == yes) {
                cd (rawdir[nsci])		
		for (i=1 ; i<=nsci ; i += 1){
			gnirs_reduction(objectname[i],objectname[i],rawdir[i],scitot[i],tellur_ext,flat_ext,arc_ext,"y",dirtot[i])
				
		}
		cd(home)
		object = no
		telluric= no
		flat = no
		arc = no
		nsci=0
		i=0
		print("DONE: ",semester,date,subdir,range)
		
	}
	

	

	

} 
end
