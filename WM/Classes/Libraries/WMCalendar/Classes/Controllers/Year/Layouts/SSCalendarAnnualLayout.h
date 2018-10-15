//
//  SSCalendarAnnualLayout.h
//  Pods
//
//  Created by Steven Preston on 7/23/13.
//  Copyright (c) 2013 Stellar16. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface SSCalendarAnnualLayout : UICollectionViewFlowLayout
@property (nonatomic) NSInteger nbColumns;
@property (nonatomic) NSInteger nbLines;
- (void)updateLayoutForBounds:(CGRect)bounds;

@end
