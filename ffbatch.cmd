rem /* --- mp4 encoder ---
@rem This batch file calls itself as javascript -- see js part below
@rem Set the correct path of ffmpeg executable in line 25.
@echo off
rem ------------------------------
rem Drop file or folder to script
rem ------------------------------
rem Recodes files to the same directory with .mp4 extension if not exists
rem Skips existing file
rem runs "c:\progs\Video Encoders\FFmpeg\64-bit\ffmpeg.exe" -i %1 -vcodec mpeg4 -b:v 32M -y %1.mp4
rem returns only when finished
rem -o				overwrite existing files
rem -b <bitrate>	output bitrate in bit/s, you may use k or M postfixes, e.g. 32M (default)
rem -p <n>			number of parallel processes (default 3)
rem -f <pattern>	RE pattern to filter processed files
rem Filenames must not contain spaces!

cscript //E:jscript "%~dp0\ffbatch.cmd" %1 %2 %3
pause
exit

rem  Javascript part */ = 0;

// Global settings
var commandbase = "\"c:\\progs\\Video Encoders\\FFmpeg\\64-bit\\ffmpeg.exe\"";
var outputextension = 'mp4';	// Ehhez még hozzá fogja fűzni a bitrate értékét is.
var exts = ['mpeg', 'mpg', 'avi', 'mkv', 'mov', 'mxf'];
var ffoptions = '-vtag xvid -vf yadif=3:1,mcdeint=2:1';
var charmap = [
	'á,é,í,ó,ö,ő,ú,ü,ű,ć,č,ď,ĺ,ł,š,ś,ż,ž,ą,ę,ţ,ç', 
	'a,e,i,o,o,o,u,u,u,c,c,d,l,l,s,s,z,z,a,e,t,c'];

// Default option values
var ps = 3; 					// Párhuzamos processzek maximális száma
var f_overwrite = 0;
var f_bitrate = '32M';
var pattern = '';

Array.prototype.indexOf = function(value) {
    for(var i=0;i<this.length;i++) {
        if(this[i]==value) return i;
    }
    return -1;
};

// Global objects and constants
var ForReading = 1;
var WshRunning = 0; 
var fso = new ActiveXObject("Scripting.FileSystemObject");
var WshShell = new ActiveXObject("WScript.Shell");
var comspec = WshShell.ExpandEnvironmentStrings("%comspec%");
var re = null;

// Determine input file
if(WScript.Arguments.length<1) {
	WScript.Echo("Using: mp4re filename options");
	WScript.Echo("Options:");
	WScript.Echo("\t-o overwrite existing result file");
	WScript.Echo("\t-b <bitrate>\toutput bitrate in bit/s, you may use k or M postfixes,\n\t\t\te.g. 32M (default)");
	WScript.Echo("\t-b <n>\tnumber of parallel processes (default 3)");
	WScript.Echo("\t-f <pattern>\tRE pattern to filter processed files");
	WScript.Echo("Filename may be a directory name, in this case all files in it \nwill be processed. Filenames must not contain spaces!");
	WScript.Quit(1);
}

var filename = WScript.Arguments.Item(0);

// Determine options
for(var i=1;i<WScript.Arguments.length;i++) {
	if(WScript.Arguments.Item(i)=='-o') f_overwrite = 1;
	if(WScript.Arguments.Item(i)=='-b') f_bitrate = WScript.Arguments.Item(++i);
	if(WScript.Arguments.Item(i)=='-p') ps = WScript.Arguments.Item(++i);
	if(WScript.Arguments.Item(i)=='-f') pattern = WScript.Arguments.Item(++i);
}

if(pattern) re = new RegExp(pattern);

// Detect directory
if(fso.FolderExists(filename)) {
	WScript.Echo(filename + " is a folder.");
    var folderspec = filename;
    var folder = fso.GetFolder(folderspec);
    var fc = new Enumerator(folder.files);
    var processes = new Array(ps);
    for(;!fc.atEnd(); fc.moveNext()) {
    	var filename1 = fc.item().Name;
        var ext = fso.GetExtensionName(filename1).toLowerCase();
        // Skip unsupported extensions
        if(exts.indexOf(ext)==-1) continue;
		
        // Skip processed files
        if(filename1.indexOf('.'+f_bitrate+'.')!=-1) continue;
		
		// Skip filtered files
		if(pattern && !re.test(filename1)) continue;
		
        var path1 = folderspec+'\\'+filename1;
        // Waiting for empty slot
        //var p = waitForFree(processes);
        var oExec = process_file(path1, f_overwrite, f_bitrate);
        //processes[p] = oExec;
    }
    // Waiting for finish all process
    //waitForFinish(processes);
    WScript.Echo("Folder process completed.\n");
    WScript.Quit(0);
} 

// Detect one file
if(!fso.FileExists(filename)) {
	WScript.Echo("Input file " + filename + " does not exist, skipping.");
	WScript.Quit(1);
}

var oExec = process_file(filename, f_overwrite, f_bitrate);

// wait for complete
if(oExec) while(oExec.Status == WshRunning) WScript.Sleep(100);

/*-------------------------------------------------------------------------------*/

/*
 *  Visszaadja a process tömb első üres elemét.
 *  Ha nincs, vár egy processs befejezéséig
 */
function waitForFree(processes) {
	var l = processes.length;
    var s = 0;
    var f = -1;
    while((f = firstFree(processes))==-1) {
        WScript.Sleep(100);
        if((s++ % 10)==0) WScript.StdOut.Write(l);
    }
    return f;
}

/*
 *  Vár az összes process befejezéséig
 */
function waitForFinish(processes) {
	var l = processes.length;
    for(var i=0;i<l;i++) {
        p = processes[i];
        if(!p) continue;
        var s = 0;
        while(p.Status == WshRunning) {
            WScript.Sleep(100);
            if((s++ % 10)==0) WScript.StdOut.Write('.'+l);
        }
    }
}

/*
 *  Vissazadja a process tömb első üres vagy már nem futó indexét
 *  -1, ha nincs üres eleme
*/
function firstFree(processes) {
    for(var i=0;i<processes.length;i++) {
        p = processes[i];
        if(!p) return i;
        if(p.Status != WshRunning) {
            processes[i] = false;
            return i;
        }
    }
    return -1;
}

/*
 *  Átkódol egy fájlt, új névvel
 *
 *  @param filename -- kódolandó fájl neve
 *  @param f_overwrite -- 1=meglévő fájlt felülírja
 *  @param f_bitrate -- pl. 192k
 *  @return processz-azonosító vagy null
 */
function process_file(filename, f_overwrite, f_bitrate) {
    var ext = fso.GetExtensionName(filename).toLowerCase();
    var inputpath = fso.getParentFolderName(filename);
    WshShell.CurrentDirectory = inputpath;
    
    // Determine output file
    var ext = fso.GetExtensionName(filename1).toLowerCase();
	var filename_base = filename.replace(new RegExp("\\."+ext+"$"), "");
	var filename_base = mapChars(filename_base.toLowerCase(), charmap);
    var filename2 = filename_base + '.'+f_bitrate+'.'+outputextension;
    if(fso.FileExists(filename2)) {
    	if(f_overwrite) {
    		WScript.Echo("Output file " + filename2 + " exist, overwriting.");
    	}
    	else {
    		WScript.Echo("Output file " + filename2 + " exist, skipping.");
    		return null;
    	}
    }
        
    // Running job, e.g ... -i %1 -vcodec mpeg4 -b:v 16M -y %1.16M.mp4
    var command = commandbase + ' -i ' + filename + ' -vcodec mpeg4 -b:v ' + f_bitrate + ' -y ' + filename2; 
    WScript.Echo("\nProcessing file " + filename);
    WScript.Echo(command);
    var oExec = WshShell.Run(command, 4, true);
    return oExec;    
}

/**
 *	A stringben lecseréli a cseretérkép elemeit (egy menetes)
 *	@param s -- a bemeneti string
 *  @param map -- kételemű tömb, első eleme a lecserélendő elemek stringje ,-kel elválasztva, második hasonlóképpen a csereértékek
 *	Ha a csereértékek kevesebben vannak, hiba keletkezik
 */
function mapChars(s, map) {
	var aa = charmap[0].split(/,/);
	var bb = charmap[1].split(/,/);
	for(var i=0;i<aa.length;i++) {
		s = s.replace(aa[i], bb[i]);
	}
	return s;
}

