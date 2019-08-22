//
//  SSCalendarAnnualViewController.m
//  Pods
//
//  Created by Steven Preston on 7/19/13.
//  Copyright (c) 2013 Stellar16. All rights reserved.
//

#import "SSCalendarAnnualViewController.h"
#import "SSCalendarMonthlyViewController.h"
#import "SSCalendarAnnualDataSource.h"
#import "SSYearNode.h"
#import "SSMonthNode.h"
#import "SSConstants.h"
#import "SSDataController.h"
#import "SSCalendarCountCache.h"

@interface SSCalendarAnnualViewController() {
    BOOL isFirstLoaded;
}

@property (nonatomic, strong) SSDataController *dataController;

@end

@implementation SSCalendarAnnualViewController

- (id)initWithEvents:(NSArray *)events years:(NSArray *)years
{
//    NSBundle *bundle = [SSCalendarUtils calendarBundle];
    if (self = [super initWithNibName:@"SSCalendarAnnualViewController" bundle:nil]) {

        self.dataController = [[SSDataController alloc] init];
        [_dataController setCalendarYearsWithValue:years];
        [_dataController setEvents:events];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = [[SSCalendarAnnualDataSource alloc] initWithView:_yearView];
    _yearView.dataSource = _dataSource;
    _yearView.delegate = self;

    _dataSource.years = _dataController.calendarYears;

    [_yearView reloadData];
    
    // NavigationBar
    UINavigationBar *navigationBar = [self.navigationController navigationBar];
    [navigationBar setBarTintColor:[UIColor colorWithRed:169.0f/255.0f green:44.0f/255.0f blue:49.0f/255.0f alpha:1.0]];
    [navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName]];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    
    // Back button
    UIView* leftButtonView = [[UIView alloc]initWithFrame:CGRectMake(-36, -3, 110, 50)];
    
    UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    leftButton.backgroundColor = [UIColor clearColor];
    leftButton.frame = leftButtonView.frame;
    [leftButton setImage:[self imageWithImage:[UIImage imageNamed:@"back.png"] convertToSize:CGSizeMake(22, 23)] forState:UIControlStateNormal];
    [leftButton setTitle:@"Back" forState:UIControlStateNormal];
    leftButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
    leftButton.tintColor = [UIColor whiteColor];
    leftButton.autoresizesSubviews = YES;
    leftButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    [leftButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    [leftButtonView addSubview:leftButton];
    UIBarButtonItem* leftBarButton = [[UIBarButtonItem alloc]initWithCustomView:leftButtonView];
    
    [self.navigationItem setLeftBarButtonItems:@[leftBarButton] animated:NO];
    _yearView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!isFirstLoaded) {
        [self gotoLastYearWithAnimate:NO];
        isFirstLoaded = YES;
        _yearView.hidden = NO;
    }
}

- (void)backAction : (id)sender {
    [self.navigationController dismissViewControllerAnimated:true completion:^{}];
}

- (IBAction)firstAction:(id)sender {
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [_yearView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [_yearLabel setText:[NSString stringWithFormat:@"%li", (long)((SSYearNode *)_dataSource.years[0]).value]];
}

- (IBAction)previousAction:(id)sender {
    NSArray *visibleItems = _yearView.indexPathsForVisibleItems;
    NSIndexPath *currentItem = [visibleItems objectAtIndex:0];
    NSInteger section = currentItem.section;
    
    if (section == 0) {
        return;
    }
    
    NSIndexPath *nextItem = [NSIndexPath indexPathForItem: 4 inSection:section -1];
    [_yearView scrollToItemAtIndexPath:nextItem atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [_yearLabel setText:[NSString stringWithFormat:@"%li", (long)((SSYearNode *)_dataSource.years[section - 1]).value]];
}

- (IBAction)nextAction:(id)sender {
    NSArray *visibleItems = _yearView.indexPathsForVisibleItems;
    NSIndexPath *currentItem = [visibleItems objectAtIndex:0];
    NSInteger section = currentItem.section;
    
    if (section == _yearView.numberOfSections - 1) {
        return;
    }
    
    NSIndexPath *nextItem = [NSIndexPath indexPathForItem: 4 inSection: section + 1];
    [_yearView scrollToItemAtIndexPath:nextItem atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [_yearLabel setText:[NSString stringWithFormat:@"%li", (long)((SSYearNode *)_dataSource.years[section + 1]).value]];
}

- (IBAction)lastAction:(id)sender {
    [self gotoLastYearWithAnimate:YES];
}

- (void) gotoLastYearWithAnimate:(BOOL)animate  {
    NSInteger section = _yearView.numberOfSections - 1;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:11 inSection:section];
    [_yearView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animate];
    [_yearLabel setText:[NSString stringWithFormat:@"%li", (long)((SSYearNode *)_dataSource.years[section]).value]];

}


- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [_dataSource updateLayoutForBounds:_yearView.bounds];
}


#pragma mark - UICollectionViewDelegateMethods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SSYearNode *year = _dataSource.years[indexPath.section];

    SSCalendarMonthlyViewController *viewController = [[SSCalendarMonthlyViewController alloc] initWithDataController:_dataController];
    
    NSInteger section = indexPath.section * year.months.count + indexPath.row;
    NSIndexPath *startingIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    
    viewController.startingIndexPath = startingIndexPath;

    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSArray *visibleItems = _yearView.indexPathsForVisibleItems;
    NSIndexPath *currentItem = [visibleItems objectAtIndex:0];
    NSInteger section = currentItem.section;
    
    [_yearLabel setText:[NSString stringWithFormat:@"%li", (long)((SSYearNode *)_dataSource.years[section]).value]];
}

@end
