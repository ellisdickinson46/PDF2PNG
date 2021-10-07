--
--  AppDelegate.applescript
--  PDF2PNG
--
--  Created by Ellis Dickinson on 01/09/2021.
--  
--

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use framework "Quartz"
use framework "Foundation"


script AppDelegate
	property parent : class "NSObject"
    
    -- Linking to Objective-C Class
    property PDFLib: class "PDFLib"
    
	-- IBOutlets
	property theWindow : missing value
    property theBeginBtn: missing value
    property theCancelBtn: missing value
    
    property thePrimaryInfoLbl: missing value
    property theAdditionalInfoLabel: missing value
    property theEnableLeadingZerosChkBx: missing value
    property theResolutionComboBox: missing value
    property theProgressIndicator: missing value
    
    -- Running Variables
    property summaryPageCount: 0
    property conversionResolution: 300
    property selectedFiles: missing value
    
    -- Running Flags
    property enableLeadingZeros: 1
    
	
    -- MARK: - Beginning of User Interface Refresh/Update Functions
    
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened
        set arguments to (current application's NSProcessInfo's processInfo's arguments) as list
        set arguments to getPDFPaths(arguments)
        if arguments = ()
            set my selectedFiles to missing value
        else
            set my selectedFiles to arguments
        end if
        log arguments
	end applicationWillFinishLaunching_
	
    on applicationDidFinishLaunching_(aNotification)
        log my selectedFiles
        my updatePrimaryStatusBkg_("Standby")
        
        if my selectedFiles = missing value
            my updateAdditionalStatusBkg_("Awaiting User Input...")
        else
            repeat with i in my selectedFiles
                set currentFileTotalPageCount to my PDFPageCount(i)
                set my summaryPageCount to my summaryPageCount + currentFileTotalPageCount
                
                log i
                log currentFileTotalPageCount
            end repeat
        
            my updateAdditionalStatusBkg_("Files provided to droplet. Press 'Begin Conversion'.")
            log "Total Steps to Convert: " & my summaryPageCount
        end if
        
        theWindow's display()
        activate
    end applicationDidFinishLaunching_
    
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    on applicationShouldTerminateAfterLastWindowClosed_(sender)
        -- Ensures the application will fully quit after processing is complete
        return true
    end applicationShouldTerminateAfterLastWindowClosed_
    -- MARK: End of User Interface Refresh/Update Functions -
    
    
    
    
    (*
        Called when 'Begin processing' is pressed.
        Will control primary workflow of script.
    *)
    on applicationBeginsProcessing_(sender)
        -- Bring window to foreground
        activate
        
        setNextInterfaceStateBkg_(false)
        
        -- For assistance debugging
        log "Enable Leading Zero State: " & (enableLeadingZeros as boolean as string)
        log "Selected Resolution: " & conversionResolution
        
        -- If no files provided, present selection UI
        if my selectedFiles = missing value
            try
                my updateAdditionalStatusBkg_("No files provided, awaiting file input...")
                set my selectedFiles to my FileChooser()
            on error
                setNextInterfaceStateBkg_(true)
                return
            end try
        end if
        
        
        try
            set PDFPaths to my getPDFPaths(my selectedFiles)
            log PDFPaths
            -- If no PDF files found
            if PDFPaths is {} then
                set errmsg to "Could not find any PDF documents."
                my dsperrmsg(errmsg, "--")
                
                -- Will trigger file selection on second attempt to run
                set my selectedFiles to missing value
                
                -- Re-enabling interface
                my updateAdditionalStatusBkg_("Invalid files provided, awaiting file input...")
                setNextInterfaceStateBkg_(true)
                
                return
            end if
        on error errmsg number errnum
            my dsperrmsg(errmsg, "--")
            set my selectedFiles to missing value
            my updateAdditionalStatusBkg_("Invalid files provided, awaiting file input...")
            setNextInterfaceStateBkg_(true)
            return
        end try
        
        
        my updatePrimaryStatusBkg_("Converting")
        my updateAdditionalStatusBkg_("Preparing to convert...")
        
        
        
        
        
        -- Processing the PDF files
        repeat with PDFPath in PDFPaths
            log PDFPath
            set fileName to (do shell script "basename " & quoted form of PDFPath)
            
            my theProgressIndicator's setDoubleValue_(0)
            my updateAdditionalStatusBkg_("Processing: " & filename)
            
            -- Did user provide a resolution?
            if conversionResolution is not missing value then
                -- Yes, proceed with conversion
                set PDFPageCount to (my PDFPageCount(PDFPath))
                my theProgressIndicator's setMaxValue_(PDFPageCount)
                
                log "Converting: " & fileName
                
                
                repeat with currentPage from 1 to PDFPageCount
                    set currentProgress to currentPage
                    my updateAdditionalStatusBkg_("Processing: (" & currentPage & "/" & PDFPageCount & ") " & filename)
                    log "    Processing: Page " & currentPage & " of " & PDFPageCount
                    
                    my theProgressIndicator's setDoubleValue_(currentProgress)
                    
                    my pdf2png(PDFPath, conversionResolution, currentPage, PDFPageCount)
                end repeat
            end if
        end repeat
        
        set currentProgress to currentPage
        my theProgressIndicator's setDoubleValue_(currentProgress)
        
        
        
        my updatePrimaryStatusBkg_("Conversion Complete")
        my updateAdditionalStatusBkg_("All files converted. Application will terminate now.")
        delay 0.5
        
        -- Terminate Main Application Window
        quit()
    end applicationBeginsProcessing_
    
    on quitApplication_(sender)
        quit()
    end quitApplication_
    
    
    
    
    
    
    
    
    
    
    
    
    on FileChooser()
        set theDocument to choose file with prompt "Please select the document(s) to convert:" of type {"PDF"} ¬
        with multiple selections allowed without invisibles
        return result
    end FileChooser
    
    
    (*
        Converts single PDF page to PNG, following naming convention
        [PDF file path must be passed as an unquoted POSIX path]
        [Dependency required: GhostScript]
    *)
    on pdf2png(PDFPath, resolution, currentPage, pageCount)
        -- Additional Logic to add Leading Zeros to Filename
        set currentPageWithLeading to currentPage
        if (enableLeadingZeros as boolean) is true then
            set currentPageStrLength to the length of (currentPage as string)
            set pageCountStrLength to the length of (pageCount as string)
            set numberOfLeading to pageCountStrLength - currentPageStrLength
            
            repeat numberOfLeading times
                set currentPageWithLeading to "0" & (currentPageWithLeading as string)
            end repeat
        end if
        

        set outputPath to (text 1 thru -5 of PDFPath) & "_Page" & "" & currentPageWithLeading & ".png"
        log "    Output Path: " & outputPath
        do shell script "/usr/local/bin/gs " & ¬
            "-dSAFER " & ¬
            "-dQUIET " & ¬
            "-dNOPLATFONTS " & ¬
            "-dNOPAUSE " & ¬
            "-dBATCH " & ¬
            "-sOutputFile='" & outputPath & "' " & ¬
            "-sDEVICE=png16m " & ¬
            "-r" & resolution & " " & ¬
            "-dTextAlphaBits=4 " & ¬
            "-dGraphicsAlphaBits=4 " & ¬
            "-dUseCIEColor " & ¬
            "-dUseTrimBox " & ¬
            "-dFirstPage=" & currentPage & " " & ¬
            "-dLastPage=" & currentPage & " '" & ¬
            PDFPath & "'"
    end pdf2png
    
    (*
    Will search for PDF files in dropped items
    Returns a list of unquoted POSIX file paths
    *)
    on getPDFPaths(droppedItems)
        set PDFPaths to {}
        repeat with droppedItem in droppedItems
            try
                set iteminfo to info for droppedItem
                if folder of iteminfo is false and name extension of iteminfo is "pdf" then
                    set PDFPaths to PDFPaths & (POSIX path of (droppedItem as Unicode text))
                end if
            on error errmsg number errnum
                log errmsg & "(" & errnum & ")"
            end try
        end repeat
        return PDFPaths
    end getPDFPaths
    
    
    (*
    Will return the number of pages within a PDF Document as Integer
    Calls from class define in PDFLib.m
    *)
    on PDFPageCount(PDFPath)
        try
            set inNSURL to current application's |NSURL|'s fileURLWithPath:(POSIX path of PDFPath)
            set pdfLibInstance to PDFLib's alloc()'s init()
            pdfLibInstance's PDFPageCounter_(inNSURL)
        on error errmsg number errnum
            display dialog errmsg
        end try
    end PDFPageCount
    
    -- MARK: - Beginning of User Interface Refresh/Update Functions

    (*
        Update the Supplementary Line of Status Info Label
    *)
    on updateAdditionalStatusBkg_(additionalStatus)
        theAdditionalInfoLabel's setStringValue_(additionalStatus)
        theWindow's display()
        delay 0.1
    end updateAdditionalStatusBkg_
    
    -- Update the Primary Status Info Label
    on updatePrimaryStatusBkg_(primaryStatus)
        thePrimaryInfoLbl's setStringValue_(primaryStatus)
        theWindow's display()
        delay 0.1
    end updatePrimaryStatusBkg_
    
    -- Enable/Disable Interface
    on setNextInterfaceStateBkg_(nextInterfaceState)
        theBeginBtn's setEnabled_(nextInterfaceState)
        theCancelBtn's setEnabled_(nextInterfaceState)
        theEnableLeadingZerosChkBx's setEnabled_(nextInterfaceState)
        theResolutionComboBox's setEnabled_(nextInterfaceState)
    end setNextInterfaceStateBkg_
    
    -- MARK: End of User Interface Refresh/Update Functions -
end script
