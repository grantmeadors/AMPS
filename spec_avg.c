/*
*  Copyrigh (C) 2007 Gregory Mendell
*
*  This program is free software; you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation; either version 2 of the License, or
*  (at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with with program; see the file COPYING. If not, write to the
*  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*  MA  02111-1307  USA
*/

/**
 * \file
 * \ingroup pulsarApps
 */

#define LAL_USE_OLD_COMPLEX_STRUCTS

/*temporary rubbish bin for headers*/
/*These are included in HeterodyneCrabPulsar files
#include <lal/LALStdlib.h>
#include <lal/AVFactories.h>
#include <lal/LALConstants.h>
#include <lal/BinaryPulsarTiming.h>*/
/*end of temporary rubbish bin*/

/*LAL header files*/
#include <lalapps.h>
#include <lal/LALDatatypes.h>
#include <lal/LALStdio.h>
#include <lal/UserInput.h>
#include <lal/SFTfileIO.h>
#include <lal/NormalizeSFTRngMed.h>
#include <lal/LALMalloc.h>

/*normal c header files*/
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <lal/Date.h>/*cg; needed to use lal routine GPStoUTC, which is used to convert GPS seconds into UTC date*/

#define NUM 1000 
/*used for defining structures such as crabOutput*/

int main(int argc, char **argv)
{
    FILE *fp  = NULL;
    FILE *fp2 = NULL;
    FILE *fp3 = NULL;
    FILE *fp4 = NULL;
    LALStatus status = blank_status;
    
    SFTCatalog *catalog = NULL;
    SFTVector *sft_vect = NULL;
    INT4 i,j,ii,nside,count;
    //    INT4 l,k;
    INT4 numBins, nSFT, nSFTcheck;
    SFTConstraints constraints=empty_SFTConstraints;
    LIGOTimeGPS startTime, endTime; 
    //    REAL8 avg =0;
    REAL8 *timeavg =NULL, *timeavgwt=NULL, *sumweight=NULL;
    REAL8 PSD,AMPPSD,PSDWT,AMPPSDWT,weight,thispower,thisavepower,scalefactor,sumpower;
    REAL8 f =0, f0, deltaF;
    CHAR outbase[256],outfile[256],outfile2[256],outfile3[256], outfile4[256]; /*, outfile6[256]; */
    //    REAL8 NumBinsAvg =0;
    REAL8 timebaseline =0;
    
    BOOLEAN help = 0;
    CHAR *SFTpatt = NULL;
    CHAR *IFO = NULL;
    INT4 startGPS = 0;
    INT4 endGPS = 0;
    INT4 checkforoutliers=1;
    REAL8 f_min = 0.0;
    REAL8 f_max = 0.0;
    REAL8 freqres =0.0;
    INT4 blocksRngMed = 101;
    CHAR *outputBname = NULL;
    //    INT4 cur_epoch = 0, next_epoch = 0;
    
    /* these varibales are for converting GPS seconds into UTC time and date*/
    //    LALUnixDate       date;
    //    CHARVector        *timestamp = NULL;
    CHARVector	     *year_date = NULL;
    //    REAL8Vector     *timestamps=NULL;
    
    CHAR *psrInput = NULL;
    CHAR *psrEphemeris = NULL;
    CHAR *earthFile = NULL;
    CHAR *sunFile = NULL;
  /*========================================================================================================================*/
    
    printf("Starting spec_avg...\n");

    lalDebugLevel = 0;
    LAL_CALL (LALGetDebugLevel(&status, argc, argv, 'v'), &status);
    
    LAL_CALL(LALRegisterBOOLUserVar  (&status, "help",         'h', UVAR_HELP,     "Print this help message",     &help        ), &status);
    LAL_CALL(LALRegisterSTRINGUserVar(&status, "SFTs",         'p', UVAR_REQUIRED, "SFT location/pattern",        &SFTpatt     ), &status);
    LAL_CALL(LALRegisterSTRINGUserVar(&status, "IFO",          'I', UVAR_REQUIRED, "Detector",                    &IFO         ), &status);
    LAL_CALL(LALRegisterINTUserVar   (&status, "startGPS",     's', UVAR_REQUIRED, "Starting GPS time",           &startGPS    ), &status);
    LAL_CALL(LALRegisterINTUserVar   (&status, "endGPS",       'e', UVAR_REQUIRED, "Ending GPS time",             &endGPS      ), &status);
    LAL_CALL(LALRegisterREALUserVar  (&status, "fMin",         'f', UVAR_REQUIRED, "Minimum frequency",           &f_min       ), &status);
    LAL_CALL(LALRegisterREALUserVar  (&status, "fMax",         'F', UVAR_REQUIRED, "Maximum frequency",           &f_max       ), &status);
    LAL_CALL(LALRegisterINTUserVar   (&status, "blocksRngMed", 'w', UVAR_OPTIONAL, "Running Median window size",  &blocksRngMed), &status);
    LAL_CALL(LALRegisterSTRINGUserVar(&status, "outputBname",  'o', UVAR_OPTIONAL, "Base name of output files",   &outputBname ), &status);
    LAL_CALL(LALRegisterREALUserVar  (&status, "freqRes",      'r', UVAR_REQUIRED, "Spectrogram freq resolution", &freqres     ), &status);
    LAL_CALL(LALRegisterREALUserVar  (&status, "timeBaseline", 't', UVAR_REQUIRED, "The time baseline of sfts",   &timebaseline), &status);
    LAL_CALL(LALRegisterSTRINGUserVar(&status, "psrInput",     'P', UVAR_OPTIONAL, "name of tempo pulsar file",   &psrInput ), &status);
    LAL_CALL(LALRegisterSTRINGUserVar(&status, "psrEphemeris", 'S', UVAR_OPTIONAL, "pulsar ephemeris file",   &psrEphemeris ), &status);
    LAL_CALL(LALRegisterSTRINGUserVar(&status, "earthFile",  'y', UVAR_OPTIONAL, "earth .dat file",   &earthFile ), &status);
    LAL_CALL(LALRegisterSTRINGUserVar(&status, "sunFile",   'z', UVAR_OPTIONAL, "sun .dat file",   &sunFile ), &status);
    
    LAL_CALL(LALUserVarReadAllInput(&status, argc, argv), &status);
    if (help)
    return(0);
    
    startTime.gpsSeconds = startGPS;/*cg; startTime is a structure, and gpsSeconds is a member of that structure*/
    startTime.gpsNanoSeconds = 0;/*cg; gps NanoSeconds is also a member of the startTime structure */
    constraints.startTime = &startTime; /*cg; & operator gets the address of variable, &a is a pointer to a.  This line puts the startTime structure into the structure constraints*/
    
    endTime.gpsSeconds = endGPS;
    endTime.gpsNanoSeconds = 0;
    constraints.endTime = &endTime;/*cg; This line puts the end time into the structure constraints*/
    constraints.detector = IFO;/*cg; this adds the interferometer into the contraints structure*/
    printf("Calling LALSFTdataFind with SFTpatt=%s\n",SFTpatt);
    LALSFTdataFind ( &status, &catalog, SFTpatt, &constraints );/*cg; creates SFT catalog, uses the constraints structure*/
    printf("Now have SFT catalog with %d catalog files\n",catalog->length);

    if (catalog == NULL)/*need to check for a NULL pointer, and print info about circumstances if it is null*/
    {
        fprintf(stderr, "SFT catalog pointer is NULL!  There has been an error with LALSFTdataFind\n");
        fprintf(stderr, "LALStatus info.... status code: %d, message: %s, offending function: %s\n", status.statusCode, status.statusDescription, status.function);
        exit(0);
    }
    nSFT = catalog->length;
    if (nSFT == 0)
    {
        fprintf(stderr, "No SFTs found, please examine start time, end time, frequency range etc\n");
        exit(0);
    }

//    printf("Loading SFTs...\n");
//    LALLoadSFTs ( &status, &sft_vect, catalog, f_min,f_max);/*cg;reads the SFT data into the structure sft_vect*/
//   printf("Loaded SFTs\n");
    
    //    fprintf(stderr, "nSFT = %d\tnumBins = %d\tf0 = %f\n", nSFT, numBins,sft_vect->data->f0);/*print->logs/spectrumAverage_testcg_0.err */
    if (LALUserVarWasSet(&outputBname))
    strcpy(outbase, outputBname);
    else
    sprintf(outbase, "spec_%.2f_%.2f_%s_%d_%d", f_min,f_max,constraints.detector,startTime.gpsSeconds,endTime.gpsSeconds);/*cg; this is the default name for producing the output files, the different suffixes are just added to this*/
    sprintf(outfile,  "%s", outbase);/*cg; name of first file to be output*/
    sprintf(outfile2, "%s_timestamps", outbase);/*cg: name of second file to be output*/
    sprintf(outfile3, "%s.txt", outbase);/*cg; name of third file to be output*/
    sprintf(outfile4, "%s_date", outbase);/*cg;file for outputting the date, which is used in matlab plotting.*/

    fp = fopen(outfile, "w");/*cg;  open all three files for writing, if they don't exist create them, if they do exist overwrite them*/
    fp2 = fopen(outfile2, "w");
    fp3 = fopen(outfile3, "w");
    fp4 = fopen(outfile4, "w");

    LALCHARCreateVector(&status, &year_date, (UINT4)128); 


/*----------------------------------------------------------------------------------------------------------------*/
/*cg;  Create the third and final file, called   blah_blah_blah.txt.  This file will contain the data used in the matlab plot script to plot the normalised average power vs the frequency.*/

    /* Find time average of normalized SFTs */
    /*    LALNormalizeSFTVect(&status, sft_vect, blocksRngMed);   
	  LALNormalizeSFTVect(&status, sft_vect, blocksRngMed);   */

    scalefactor = 1.e21;

    printf("Looping over SFTs to compute average spectra\n");
    for (j=0;j<nSFT;j++)

      {
	printf("Extracting SFT %d...\n",j);
	LALExtractSFT ( &status, &sft_vect, catalog, f_min,f_max, j);/*cg;reads the SFT data into the structure sft_vect*/
	//	printf("Extracted SFT %d\n",j);

	if (sft_vect == NULL)
	  {
	    fprintf(stderr, "SFT vector pointer is NULL for file %d!  There has been an error with LALLoadSFTs\n",j);
	    fprintf(stderr, "LALStatus info.... status code: %d, message: %s, offending function: %s\n", status.statusCode, status.statusDescription, status.function);
	    exit(0);
	  }
      
	if (j==0) 
	  {
	    numBins = sft_vect->data->data->length;/*the number of bins in the freq_range*/
	    f0 = sft_vect->data->f0;
	    deltaF = sft_vect->data->deltaF;
	    printf("numBins=%d, f0=%f, deltaF=%f\n",numBins,f0,deltaF);
	    timeavg = XLALMalloc(numBins*sizeof(REAL8));
	    if (timeavg == NULL) fprintf(stderr,"Timeavg memory not allocated\n");
	    timeavgwt = XLALMalloc(numBins*sizeof(REAL8));
	    if (timeavgwt == NULL) fprintf(stderr,"Timeavgwt memory not allocated\n");
	    sumweight = XLALMalloc(numBins*sizeof(REAL8));
	    if (sumweight == NULL) fprintf(stderr,"Sumweight memory not allocated\n");
	  }

	nSFTcheck = sft_vect->length;/* the number of sfts.*/
	if (nSFTcheck != 1) 
	  {
	    fprintf(stderr, "Oops, nSFTcheck=%d instead of one\n",nSFTcheck);
	    exit(0);
	  }

	for (i=0; i<numBins; i++) 
	  {
 	    sft_vect->data[0].data->data[i].re *= scalefactor;
 	    sft_vect->data[0].data->data[i].im *= scalefactor;
	  }
	if (checkforoutliers==1)
	  {
	    sumpower = 0.;
	    for ( i=0; i < 100; i++)
	      {
		sumpower += sft_vect->data[0].data->data[i].re*sft_vect->data[0].data->data[i].re + 
		  sft_vect->data[0].data->data[i].im*sft_vect->data[0].data->data[i].im;
	      }
	  }
	printf("j=%d, sumpower=%f\n",j,sumpower);
	for ( i=0; i < numBins; i++)
	  {
	    thispower = sft_vect->data[0].data->data[i].re*sft_vect->data[0].data->data[i].re + 
	      sft_vect->data[0].data->data[i].im*sft_vect->data[0].data->data[i].im;
	    thisavepower = 0.;
	    nside = 10;
	    count = 0;
	    for (ii=-nside; ii<=nside; ii++) 
	      { 
		if ( i+ii>=0 && i+ii<numBins ) {
		  thisavepower += sft_vect->data[0].data->data[i+ii].re*sft_vect->data[0].data->data[i+ii].re + 
		    sft_vect->data[0].data->data[i+ii].im*sft_vect->data[0].data->data[i+ii].im; 
		  count++;
		}
	      }
	    thisavepower /= count;
	    weight = 1./thisavepower;
	    //	    weight = 1.;
	    if (j == 0) 
	      {
		timeavg[i] = thispower;
		timeavgwt[i] = thispower*weight;
		sumweight[i] = weight;
	      } 
	    else 
	      { 
		timeavg[i] += thispower;
		timeavgwt[i] += thispower*weight;
		sumweight[i] += weight;
	      }
	  }
	LALDestroySFTVector (&status, &sft_vect );
      }
    printf("About to do calculation of averages...\n");
    printf("Sample: timeavg[0]=%g, timeavgwt[0]=%g, sumweight[0]=%g\n",timeavg[0],timeavgwt[0],sumweight[0]);
    /*timeavg records the power of each bin*/
    for ( i=0; i < numBins; i++)
      {
        f = f0 + ((REAL4)i)*deltaF;
	PSD=2.*timeavg[i]/((REAL4)nSFT)/scalefactor/scalefactor/timebaseline;
        PSDWT = 2.*timeavgwt[i]/sumweight[i]/scalefactor/scalefactor/timebaseline;
        AMPPSD = pow(PSD,0.5);
        AMPPSDWT = pow(PSDWT,0.5);
	/*	SNR=(PWR-1)*(sqrt(((REAL4)nSFT))); */
	//        fprintf(fp3,"%16.8f %g %g %g %g %g %g\n",f, PWR, STRAIN, PWRWT, STRAINWT, timeavgwt[i], sumweight[i]);
        fprintf(fp3,"%16.8f %g %g %g %g\n",f, PSD, AMPPSD, PSDWT, AMPPSDWT);
      } 
/*------------------------------------------------------------------------------------------------------------------------*/ 
/*End of normal spec_avg code, the remaining code is for crab freq calc.*/
/*================================================================================================================*/

    /*fprintf(stderr,"end of spec_avg 1\n");*/

    /*=======================================================================================================================*/
    /*=======================================================================================================================*/

    LALDestroySFTCatalog( &status, &catalog);/*cg; desctroys the SFT catalogue*/

    /*release a;; the allocaeted memory*/
    //    LALCHARDestroyVector(&status, &timestamp);
    LALCHARDestroyVector(&status, &year_date);
    LALDestroySFTVector (&status, &sft_vect );
    /*fprintf(stderr,"end of spec_avg 2\n");*/

    if (timeavg != NULL) XLALFree(timeavg);

    /*fprintf(stderr,"end of spec_avg 3\n");*/

    LAL_CALL(LALDestroyUserVars(&status), &status);

    /*fprintf(stderr,"end of spec_avg 4\n");*/
    /*close all the files, spec_avg.c is done, all info written to the files.*/
    fclose(fp);
    fclose(fp2);
    fclose(fp3);
    fclose(fp4);

    fprintf(stderr,"end of spec_avg\n");

    return(0);


}
/* END main */
