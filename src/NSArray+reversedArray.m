//
//  NSArray+reversedArray.m
//  FilteredImageList
//
//  Created by Shamyl Zakariya on 3/28/09.
//  Copyright 2009 Shamyl Zakariya. All rights reserved.
//

#import "NSArray+reversedArray.h"


@implementation NSArray (reversedArray)

- (NSArray *)reversedArray {
	NSMutableArray *reversedArray = [[NSMutableArray alloc] init];
	
	for( id object in self ) 
	{
		[reversedArray insertObject:object atIndex:0];
	}
	
    return reversedArray;
}

@end
