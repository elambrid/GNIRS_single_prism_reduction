# Copyright(c) 2004-2012 Association of Universities for Research in Astronomy, Inc.

###############################################################################
# Gemini GNIRS example data reduction script                                  #
# Typical reduction for: Longslit Science and Calibration Data                #
#                                                                             #
# This script is provided to guide the user through the GNIRS data reduction  #
# process and may not be optimised to give the best results. It shows the     #
# reduction steps using GNIRS data and provides explanatory comments at each  #
# step.                                                                       #
#                                                                             #
# It is strongly recommended that the user read the embedded comments and     #
# understand the processing steps, since the optimum steps for a given        #
# dataset may differ, e.g., improved cleaning of cosmic rays and bad pixels   #
# and improved signal-to-noise will most likely be possible. The user can     #
# then edit this script to match their dataset.                               #
#                                                                             #
## Once this script has been properly edited, it can be run by copying and     #
## pasting each command into an IRAF or PyRAF session, or by defining this     #
# script as a task by typing:                                                 #
#                                                                             #
#   ecl> task $thisscript="thisscript.cl"                                     #
#   ecl> thisscript                                                           #
#                                                                             #
# in the IRAF or PyRAF session. It is NOT recommended to run this script      #
# using redirection i.e., cl < thisscript.cl.                                 #
#                                                                             #
# Note that this script is designed to be re-run as needed, so each step is   #
# preceded by a command to delete the files created in that step.             #
###############################################################################

# ERINI LAMBRIDES Rewrite#

###############################################################################
# STEP 1: Initialize the required packages                                    #
###############################################################################

# Load the required packages

procedure gnirs_reduction(obj_name,reduc_name,rawdir,obj_ext,tellur_ext,flat_ext,arc_ext,crosscorr,subdir)

string obj_name     
string reduc_name   
string rawdir       
string obj_ext      
string tellur_ext   
string flat_ext     
string arc_ext      
string crosscorr 
string subdir   



struct *scanfile  
struct *list2
struct *list3
struct *list4
struct *list5
struct *list6
struct *list7


string l_obj_name,l_reduc_name, l_rawdir, l_tellur_ext, l_flat_ext, l_obj_ext,l_arc_ext,l_crosscorr

 


begin



char sciobjs[5]
char tellic[5]

string image 
string tmpflat
int nimages
int j


l_obj_name = obj_name
l_reduc_name = reduc_name
l_rawdir = rawdir
l_obj_ext = obj_ext
l_tellur_ext=tellur_ext
l_flat_ext = flat_ext
l_arc_ext = arc_ext
l_crosscorr = crosscorr







# To start from scratch, delete the existing logfile

delete (gnirs.logfile, verify=no)

gnirs.logfile = l_obj_name // ".log"

delete ("gnirs_longslit.database", verify=no)

print ("deleting the existing database file")


gnirs.database = l_obj_name // "longslit_database/"


# Define the (current) directory where the raw data are located


#load header keywords for GNIRS
nsheaders ("gnirs")

# Set the display
set stdimage=imt1024


###############################################################################
#Create the reduction lists                                          #
###############################################################################



delete ("*.lis")

gemlist (l_obj_name,   l_obj_ext,          > "obj.lis")
gemlist (l_reduc_name, l_tellur_ext,       > "telluric.lis")
gemlist (l_reduc_name, l_flat_ext,         > "flats.lis")
gemlist (l_reduc_name, l_arc_ext,          > "arc.lis")

concat("obj.lis,telluric.lis,flats.lis,arc.lis","all.lis")



###############################################################################
# STEP 4: Visually inspect the data                                           #
###############################################################################
#change sleep if you actually want to inspect the data

scanfile = "all.lis"
while (fscan(scanfile, image) != EOF) {
    display (l_rawdir//image//"[1]", 1)
    sleep 0
}
scanfile = ""



###############################################################################
# STEP 5: Prepare the data                                                    #
###############################################################################

imdelete ("n@all.lis", verify=no)
print ("starting nsprepare...")
nsprepare ("@all.lis", rawpath=l_rawdir, shiftx="INDEF", shifty="INDEF",fl_forcewcs="yes",bpm="gnirs$data/gnirsn_2012dec05_bpm.fits")

#################################################################################
# STEP 11: Radiation Events Removal 						#
#################################################################################


redo:

i=0
j = 0
nimages=0

delete ("n_*", verify=no)
delete ("tell_*", verify=no)
delete ("new_*", verify=no)
delete ("node*", verify=no)
delete ("mask_node*", verify=no)
delete ("data.lis", verify=no)
delete ("objectl*", verify=no)
imdelete ("newN*", verify=no)

!cat obj.lis > "objectlist.txt"
!cat objectlist.txt
string filename

!sed 's/$/\.fits/' objectlist.txt > sciobjlist.txt
!cat sciobjlist.txt | sed '/^$/d;s/[[:blank:]]//g' > scilist.lis
char whut
list3= "scilist.lis"
while (fscan(list3,filename) != EOF) {
	j=j+1
	print (j)
	print (filename) | scan(sciobjs[j])
        nimages= j
        print(sciobjs[j])
	}
!cat telluric.lis > "telluriclist.txt"
string filename2

!sed 's/$/\.fits/' telluriclist.txt > telllist.txt
!cat telllist.txt | sed '/^$/d;s/[[:blank:]]//g' > telliclist.lis
list2= "telliclist.lis"
while (fscan(list2,filename2) != EOF) {
	i=i+1               
	print (filename2) | scan(tellic[i])    
	}
####
#for telluric
####

!sed 's/^/n/' telluric.lis > n_telluric.lis

!awk 'NR == 1 { print }END{ print }' n_telluric.lis > tell_n_node_a
!awk 'NR==2, NR==3' n_telluric.lis > tell_n_node_b
gemcombine ("@tell_n_node_a",output="tell_n_nodeatot",combine="median",reject="minmax",nhigh="1",nlow="0")
gemcombine ("@tell_n_node_b",output="tell_n_nodebtot",combine="median",reject="minmax",nhigh="1",nlow="0")


####
#for science
######
!sed 's/^/n/' obj.lis > n_obj.lis

!awk 'NR == 1 { print }END{ print }' n_obj.lis > n_node_a
!awk 'NR==2, NR==3' n_obj.lis > n_node_b
gemcombine ("@n_node_a",output="n_nodeatot",combine="median",reject="minmax",nhigh="1",nlow="0")
gemcombine ("@n_node_b",output="n_nodebtot",combine="median",reject="minmax",nhigh="1",nlow="0")

!ls tell_n_node*tot.fits > "new_telluric.lis"
!ls n_node*tot.fits > "new_obj.lis"

#####
#Turn them back into MDF's
######

fxcopy ("n"//sciobjs[1], "n_nodeatot.fits", groups = "3-4",new_file="no")
fxcopy ("n"//tellic[1], "tell_n_nodeatot.fits", groups = "3-4",new_file="no")
fxcopy ("n"//sciobjs[2], "n_nodebtot.fits", groups = "3-4",new_file="no")
fxcopy ("n"//tellic[2], "tell_n_nodebtot.fits", groups = "3-4",new_file="no")

###############################################################################
# STEP 6: Generate the normalised flat                                        #
###############################################################################

delete ("tmpflat", verify=no)

gemextn ("n//@flats.lis", proc="expand", extname="SCI", extver="1", > "tmpflat")
#imstatistic ("@tmpflat" | tee (gnirs.logfile,append=yes))
delete ("tmpflat", verify=no)

imdelete ("rn//@flats.lis", verify=no)
nsreduce ("n//@flats.lis", fl_sky=no, fl_cut=yes, fl_flat=no, fl_dark=no, fl_nsappwave=no)

imdelete ("final_flat.fits", verify=no)
nsflat ("rn//@flats.lis", flatfile="final_flat.fits")

#display (final_flat.fits[sci,1], 1)

###############################################################################
# STEP 7: Reduce the arcs                                                     #
###############################################################################

imdelete ("rn//@arc.lis", verify=no)
nsreduce ("n//@arc.lis", fl_sky=no, fl_flat=no)

###############################################################################
# STEP 8: Obtain the wavelength calibration                                   #
###########################################################################

imdelete ("wrn//@arc.lis", verify=no)
nswavelength ("rn//@arc.lis", coordlist="gnirs$data/Ar_Xe.dat", fl_inter=no)

###############################################################################
# STEP 9: Sky subtract the telluric and science data                          #
###############################################################################

# There are 3 ways to determine the correct frames for sky subtraction in
# nsreduce. If the frames are evenly spaced in time (i.e., ABBA dither
# pattern), the easiest is "skyrange=INDEF" (the default), which will determine
# the best sky frame for each image from the input list. One can also set the
# skyrange (in seconds) by hand, or provide a list of sky images directly. See
# nsreduce help for more information. If two or more images meet the sky
# selection criteria (skyrange and nodsize), they will be combined to create
# the sky frame that is subtracted.

imdelete ("r//@new_telluric.lis", verify=no)
nsreduce ("@new_telluric.lis", fl_nsappwave=no, fl_sky=yes, skyrange=1000, fl_flat=yes, flatimage="final_flat.fits")

delete ("tmpsky", verify=no)
printlog ("--------------------------------------------", gnirs.logfile, verbose=yes)
gemextn ("n//@obj.lis", proc="expand", index="0", > "tmpsky")
printlog ("Science Exposure Times: ", gnirs.logfile, verbose=yes)
#hselect ("tmpsky", "$I,UT", yes)
#printlog ("tmpsky",gnirs.logfile, append=yes)
printlog ("--------------------------------------------", gnirs.logfile, verbose=yes)
delete ("tmpsky", verify=no)

imdelete ("r//@new_obj.lis", verify=no)
nsreduce ("@new_obj.lis", fl_nsappwave=no, fl_sky=yes, skyimages="n@sky.lis", skyrange=1000, fl_flat=yes, flatimage="final_flat.fits")

###############################################################################
# STEP 10: Apply the wavelength solution to the telluric and science data     #
###############################################################################


imdelete ("fr//@new_telluric.lis", verify=no)
nsfitcoords ("r//@new_telluric.lis", lamp= "wrn//@arc.lis" )

imdelete ("tfr//@new_telluric.lis", verify=no)
nstransform ("fr//@new_telluric.lis")

imdelete ("fr//@new_obj.lis", verify=no)
nsfitcoords ("r//@new_obj.lis", lamp= "wrn//@arc.lis" )

imdelete ("tfr//@new_obj.lis", verify=no)
nstransform ("fr//@new_obj.lis")




###############################################################################
# STEP 12: Combine the telluric and science data                              #
###############################################################################

# FYI:
#
# NSSSTACK combines things at the same offset position (no shifting) and gives
#     1 output file per position. 
# NSCOMBINE shifts all data spatially to a common offset position and gives 1
#     combined output file.



imdelete ("tell_comb.fits", verify=no)
nscombine ("tfr//@new_telluric.lis", output="tell_comb",rejtype="none",masktype="none")
#display (tell_comb.fits[sci,1], 1)

imdelete ("obj_comb.fits", verify=no)
#!awk 'NR == 1 { print }END{ print }' obj.lis > comb.lis
#nscombine ("frcln//@comb.lis", output="obj_comb",rejtype="none",masktype="none")
nscombine ("tfr//@new_obj.lis", output="obj_comb",rejtype="none",masktype="none")
#display ("obj_comb.fits[sci,1]", 1) 


###############################################################################
# STEP 12: Extract the telluric and science data                              #
###############################################################################

imdelete ("xtell_comb.fits", verify=no)
nsextract ("tell_comb.fits")

#splot (xtell_comb.fits[sci,1])

imdelete ("xobj_comb.fits", verify=no)
nsextract ("obj_comb.fits", fl_inter="no",fl_apall="yes",line="343",nsum=5,ylevel=0.3)
#nsextract ("obj_comb.fits", fl_inter="yes",fl_apall="yes",ylevel=0.3)

#splot (xobj_comb.fits[sci,1])

copy("/home/elambrid/Desktop/Geballe/All/Telluric_Correction/*",".")

string temp
string s1
string s2
string s3
string s5
string Title
string star1 = ""
string name1 = ""
string temper = ""
string startype = ""
hselect ("xtell_comb.fits[sci,1]", "OBJECT" , "yes", > "object.lis")
		
!cat object.lis
list4 = "object.lis"
string spec_class = ""

while (fscan (list4,star1,name1,spec_class) != EOF) {
	print ("spectral class: ", spec_class)



print("star1: ",star1)
print("name1: ",name1)
print("spec_class: ",spec_class)


if (strstr(spec_class,"(A7V)") != 0 ){ 
  startype = "A7V_diluted_25.fits"
  temper = "7930"
  print("temp: ", temper)
  }
  
if (strstr(spec_class,"A7V") != 0){ 
  startype = "A7V_diluted_25.fits"
  temper = "7930"
  print("temp: ", temper)
  }

if (strstr(spec_class,"A1V") != 0){
  startype = "A1V.fits"
  print("temp: ", temper)
  temper = "9040"
  }
  
if (strstr(spec_class,"A1V") != 0){
  startype = "A1V.fits"
  print("temp: ", temper)
  temper = "9040"
  }

if (strstr(spec_class,"A1V") != 0){
 startype = "A1V.fits"
 print("temp: ", temper)
 temper = "9040" 
 }
}
#string allav1
#string allav2
#string v3
#while (fscan(list4,allav1,allav2,v3) != EOF) {
#  print (allav1)
#  print (allav2)
#  print (v3)
#}

#if (allav2 == "9040  A1V ") {
  
#startype = "A1V.fits"
# print("temp: ", temper)
# temper = "9040" 
# }
 
 
print ("Model Spectra Found!")
print (startype)

#################################################################################################################
# Cross Correlation 												#
#################################################################################################################

skipper:

string starname
string name
string ref
string days
string ap
string codes
string hght
string fwhm
string tdr
string vobs
string vrel
string vhelio
string verr

if (l_crosscorr == "y")  {
   imdelete ("xobj_comb_shifted*",verify="no")
   fxcor ("xobj_comb.fits[sci,1]", "xtell_comb.fits[sci,1]", osample="19800-21000", rsample="19800-21000",interactive="no")
   !grep -v '#' "fxcorr_log.txt" > "fxcorr.lis"
   list5 = "fxcorr.lis"
   real shiftx
   while (fscan (list5,starname,name,ref,days,ap,codes,shiftx,hght,fwhm,tdr,vobs,vrel,vhelio,verr) != EOF) {
   print ("shift: ", -shiftx)
   shiftline("xobj_comb.fits","xobj_comb_shifted.fits", shift=-shiftx)
   
   imdelete("sci*", verify=no)
   imdelete("standard_*", verify=no)
	
   imarith ("xobj_comb_shifted.fits[sci,1]","/","xtell_comb.fits[sci,1]",result="sci_stand_ratio_shifted")
   #onedspec
   wspectext("xobj_comb_shifted.fits[sci,1]","sci_spec_shifted")
   mk1dspec("standard_bb_spec",ncols=1022, wstart=18924, wend=25533,continuum=4.5,fnu=yes,temperature=temper)

   imarith("sci_stand_ratio_shifted","*","standard_bb_spec", result="sci_bbody_ratio")
   sarith ("sci_bbody_ratio.fits","*",startype, output="sci_fluxcal_ratio")

   wspectext("sci_fluxcal_ratio.fits[0]","sci_fluxcal_ratio.txt",header="no")
   goto over
	
}
}
else if (l_crosscorr == "n") {
	goto normal
}

##########################################################
#Normalization
##########################################################

normal:

imdelete("sci*", verify=no)
imdelete("standard_*", verify=no)

imarith ("xobj_comb.fits[sci,1]","/","xtell_comb.fits[sci,1]",result="sci_stand_ratio")
#onedspec
wspectext("xobj_comb.fits[sci,1]","sci_spec")
mk1dspec("standard_bb_spec",ncols=1022, wstart=18924, wend=25533,continuum=4.5,fnu=yes,temperature=temper)

imarith("sci_stand_ratio","*","standard_bb_spec", result="sci_bbody_ratio")
sarith ("sci_bbody_ratio","*",startype, output="sci_fluxcal_ratio")

wspectext("sci_fluxcal_ratio","sci_fluxcal_ratio.txt",header="no")

over:

hselect("sci_fluxcal_ratio.fits","object","yes", > "object_name.lis") 

list7 = "object_name.lis"


string object_name=""
fscan(list7,object_name)


copy("sci_fluxcal_ratio.txt",object_name//".txt")
fxcopy("sci_fluxcal_ratio.fits[0]",object_name//".fits")
fxcopy("xobj_comb.fits[sci,1]","x"//object_name//".fits")


mkdir("results_"//object_name)


movefiles ("J*.*","results_"//object_name)
movefiles ("xJ*","results_"//object_name)
movefiles ("xtell*","results_"//object_name)
movefiles ("obj_name",subdir)
movefiles ("n*", subdir)
movefiles ("sci*", subdir)
movefiles ("x*", subdir)
movefiles ("*.lis", subdir)
movefiles ("fxcorr.txt", subdir)
movefiles ("s*", subdir)
movefiles ("o*", subdir)
movefiles ("t*", subdir)
movefiles ("f*",subdir)
movefiles ("A*",subdir)
movefiles ("g*",subdir)
movefiles ("*longslit_database",subdir)
movefiles ("r*",subdir)
movefiles ("w*",subdir)
movefiles ("N*.log",subdir)

print ("Finished!")

end





















