//
//  SSCalendarYearHeaderView.h
//  Pods
//
//  Created by Steven Preston on 7/23/13.
//  Copyright (c) 2013 Stellar16. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface SSCalendarAnnualHeaderView : UICollectionReusableView
{
    IBOutlet UIView *separatorView;
    IBOutlet NSLayoutConstraint *separatorViewHeightConstraint;
}

@property (nonatomic, strong) IBOutlet UILabel *label;

@end
