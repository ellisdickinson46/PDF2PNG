//
//  PDFLib.h
//  PDF2PNG
//
//  Created by Ellis Dickinson on 19/09/2021.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>
#include <CoreFoundation/CoreFoundation.h>


@interface PDFLib : NSObject {
   
}

// Methods
-(void) create;
-(int) PDFPageCounter: (NSString*) formatSpecifier, ...;

@end
