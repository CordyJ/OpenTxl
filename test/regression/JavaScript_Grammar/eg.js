

//**********************************************************************************
//      Home Page Creation Script
//      (C) Copyright 1996 by Kevin Gorsline(gorsline@ix.netcom.com) 
//      For more examples go to Home Directions web site at
//     http://homedirections.com 
//     You may freely use this script. 
//      If you do, please leave this section in site and drop me a note. 
//*********************************************************************************

function addplus(items) 
   {
   var plussed = "";
   for (var t = 1 ; t <= items.length ; t++) 
      {
      if (items.substring(t-1,t) == " ") 
         {  plussed+="+";  }
      else 
         { plussed+=items.substring(t-1,t); }
      }
   return plussed;
   }

//    Do the Search
function doSearch() 
   {
   var words;
   words = document.searchforit.query.value;
   var searchitems;
   searchitems=addplus(words);
   var index;
   //  Obtain the selectedIndex properties from the search engines options for 
   index = document.searchforit.service.selectedIndex;
   if (index>=1)
      {
      var site;
      site = document.searchforit.service.options[index].value;
      site+=searchitems;
      if (notEmpty(searchitems))   
         {
         //window.open("","mainWin");
         //window.open(site,"mainWin");
         window.location=site;
         }
      }
   else
      {alert("\nYou must select a search engine.");}
   }

//     Check for empty contents in search searchitems
function notEmpty(word) 
   {
   if (word == "" || word == null) 
      {
      self.status="ENTER SEARCH searchitems";
      alert("\nYou must enter a keyword to search for."); 
      document.searchforit.query.focus();  
      return false;
      }
   else 
      {
      self.status = "SEARCHING FOR:  " + word;
      return true;
      }
   }

function howTo()
   {
   alert("\nWelcome to my JavaScript Search Engine\n\nSimply choose a search engine from the drop-down menu, enter the keyword to search for, and click on SEARCH.\n\nSeperate multiple keywords with \'and\'.");
   }

function clearIt()
   {
   document.searchforit.query.value="";
   document.searchforit.query.focus();     
   }

