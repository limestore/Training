/* Author: Vishal Bandari
 * Last Modified By: vishal.bandari@cdk.com (2 Feb 2015)
 */


// ------Validation Functions ------ //


function ValidEmail(email) {
    var re = /^([^\@]*)\@([^\.]*)\.(.*)$/;
    return re.test(email);
} 

function formatPhoneNumber(number){
    var digits = (""+number).replace(/\D/g, "");
    var match = digits.match(/1?(\d{3})(\d{3})(\d{4})$/);
    return (!match) ? digits : "(" + match[1] + ") " + match[2] + "-" + match[3];
}

// ------Conversion Functions ------ //

function DateToString(InitialDate){
    var ResultCreatedDate = new Date(InitialDate);
    var ResultCreatedDateString = "";
    
    // convert for time-zone
    ResultCreatedDate = new Date(ResultCreatedDate.setUTCHours(ResultCreatedDate.getTimezoneOffset()/60));
    
    if (InitialDate && InitialDate != "") 
    {
        ResultCreatedDateString += ResultCreatedDate.getMonth() + 1 + "/";
        ResultCreatedDateString += ResultCreatedDate.getDate() + "/";
        ResultCreatedDateString += ResultCreatedDate.getFullYear() + " ";
    }
    
    return ResultCreatedDateString;
}

function ConvertSpecialCharacters(text){
    var temp = document.createElement("div");
    temp.innerHTML = text;
    var result = temp.childNodes[0].nodeValue;
    temp.removeChild(temp.firstChild)
    return result;
}

// ------Popup Functions ------ //

function DisplayUnexpectedError(){
    MessageBox(true, "An unexpected error occurred. "
               + "There may be a number of causes such as the Salesforce session expiring. " 
               + "It is recommended to refresh your browser by clicking the Refresh button below. ", "Error", 
               {"Refresh":function(){window.location=window.location;}});
}

// ------Action Functions ------ //


function dial(event, pn, whoid, whatid){
    if(event) { event.preventDefault(); }
    
    if(ISTools && ISTools.Record){ 
        scrollToTop(); 
        ISTools.Record.dialNumber({phone_number:pn, who_id:whoid, what_id:whatid}); 
    }
}


function stopTimers() {
    for(var i in Timeouts) { clearTimeout(Timeouts[i]); }
    for(var i in Intervals) { clearInterval(Intervals[i]);  }
}

// ------Encode and Decoding Functions ------ //

function decodeEntities(s){
    var str, temp = document.createElement('p');
    temp.innerHTML = s;
    str = temp.textContent || temp.innerText;
    temp = null;
    return str;
}

/* <======>   jQuery Utility functions  <======> */

var j$ = jQuery.noConflict();
function log(e)
{
    if(console.log) 
    {
        console.log(e); 
    }
};

// ------Redirecting Functions ------ //

function redirectToObject(ObjectId,location) {
    window.open('/'+ObjectId,location);
}

function redirectToUrl(url,location){
    window.open('/'+url,location);
}

// ------Popup Functions ------ //

function MessageBox(element, show, message, title, buttons) { 
    var p = j$(element); 
    if (show) { if (!p.dialog("isOpen")) { p.dialog("open"); } } else { if(p) { p.empty(); } if (p.dialog("isOpen")) { p.dialog("close"); } }
    if (title) { p.dialog("option","title",title) } else { p.dialog("option","title","Please Wait...") }
    if (message) { if(message && message.jquery) { p.empty().append(message); } else { p.html(message); } } else { p.html("Processing..."); }
    if (buttons) { p.dialog("option","buttons",buttons); } else { p.dialog("option","buttons",{}); }
    
    return p;
}

// ------Animation Functions ------ //

function scrollToTop() {
    j$("html, body").animate({ scrollTop: 0 }, "slow");
}

function scrollToBottom() {
    j$("html, body").animate({ scrollTop: j$(document).height() }, "slow");
}

