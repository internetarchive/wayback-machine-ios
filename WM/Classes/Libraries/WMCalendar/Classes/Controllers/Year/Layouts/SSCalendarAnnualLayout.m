//
//  SSCalendarAnnualLayout.m
//  Pods
//
//  Created by Steven Preston on 7/23/13.
//  Copyright (c) 2013 Stellar16. All rights reserved.
//

#import "SSCalendarAnnualLayout.h"

@implementation SSCalendarAnnualLayout

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.headerReferenceSize = CGSizeMake(0, 51.0f);
    self.minimumInteritemSpacing = 9.0f;
    self.minimumLineSpacing = 9.0f;
    self.sectionInset = UIEdgeInsetsMake(0, 10.0f, 0, 10.0f);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.nbColumns = -1;
    self.nbLines = -1;
}


- (id)init
{
    self = [super init];
    if (self) {
        [self awakeFromNib];
    }
    return self;
}

- (void)updateLayoutForBounds:(CGRect)bounds
{

    CGFloat width = (bounds.size.width - 10.0f - 10.0f - 9.0f - 9.0f) / 3;
    self.itemSize = CGSizeMake(width, width + 17.0f);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger nbColumns = 3;
    NSInteger nbLines = 4;
    
    NSInteger idxPage = (int)indexPath.row/(nbColumns * nbLines);
    
    NSInteger O = indexPath.row - (idxPage * nbColumns * nbLines);
    
    NSInteger xD = (int)(O / nbColumns);
    NSInteger yD = O % nbColumns;
    
    NSInteger D = xD + yD * nbLines + idxPage * nbColumns * nbLines;
    
    NSIndexPath *fakeIndexPath = [NSIndexPath indexPathForItem:D inSection:indexPath.section];
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:fakeIndexPath];
    
    // return them to collection view
    return attributes;
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    CGFloat newX = MIN(0, rect.origin.x - rect.size.width/2);
    CGFloat newWidth = rect.size.width*2 + (rect.origin.x - newX);
    
    CGRect newRect = CGRectMake(newX, rect.origin.y, newWidth, rect.size.height);
    
    // Get all the attributes for the elements in the specified frame
    NSArray *allAttributesInRect = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:newRect] copyItems:YES];
    
    for (UICollectionViewLayoutAttributes *attr in allAttributesInRect) {
        UICollectionViewLayoutAttributes *newAttr = [self layoutAttributesForItemAtIndexPath:attr.indexPath];
        
        attr.frame = newAttr.frame;
        attr.center = newAttr.center;
        attr.bounds = newAttr.bounds;
        attr.hidden = newAttr.hidden;
        attr.size = newAttr.size;
    }
    
    return allAttributesInRect;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return YES;
}

@end
