//
//  PDFLib.m
//  PDF2PNG
//
//  Created by Ellis Dickinson on 19/09/2021.
//

#import "PDFLib.h"


@implementation PDFLib
-(void) create {
    // This is a testing function
    NSLog(@"Hi !!");
}

-(int) PDFPageCounter: (NSURL*) passedResourcePath, ... {
    // Create NSURL from a NSString (not used)
    // ---------------------------------------
    // NSString *pathToPdfDoc = [[NSBundle mainBundle] pathForResource:@"pdfPath" ofType:@"pdf"];
    // NSURL *pdfUrl = [NSURL fileURLWithPath:pathToPdfDoc];
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL((CFURLRef)passedResourcePath);
    int pageCount = (int) CGPDFDocumentGetNumberOfPages(document);
       
    // Count the pages within the specified document CGPDFDocumentGetNumberOfPages(document);
    return pageCount;
}

@end
