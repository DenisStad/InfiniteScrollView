//
//  InfiniteScrollView.m
//  test
//
//  Created by Denis Stadniczuk on 11/12/13.
//  Copyright (c) 2013 Denis Stadniczuk. All rights reserved.
//

#import "InfiniteScrollView.h"

@implementation InfiniteScrollViewCell

-(id)initWithIdentifier:(NSString*)identifier
{
   if (self = [super init]) {
      self.identifier = identifier;
   }
   return self;
}

@end

@interface InfiniteScrollView () <UIScrollViewDelegate>
{
   NSMutableArray *visibleCells;

   UIScrollView *scrollView;
   NSMutableDictionary *cachedCells;
}

@end

@implementation InfiniteScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

       scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
       scrollView.delegate = self;
       scrollView.showsHorizontalScrollIndicator = NO;
       scrollView.showsVerticalScrollIndicator = NO;
       [self addSubview:scrollView];

       visibleCells = [[NSMutableArray alloc] init];

       [self addObserver:self forKeyPath:@"dataSource" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
   if ([keyPath isEqualToString:@"dataSource"]) {
      [self reloadData];
   }
}

#define kEndZoneLength 100.0f

-(void)reloadData
{
   for (UIView *view in scrollView.subviews) {
      [view removeFromSuperview];
   }

   if (self.dataSource == nil) {
      return;
   }
   scrollView.frame = self.bounds;

   cachedCells = [NSMutableDictionary dictionary];

   int currentLastIndex = -1;

   float currentEnd = 0;
   float length = self.orientation == InfiniteScrollViewOrientationVertical? self.frame.size.height : self.frame.size.width;
   float offset = kEndZoneLength + length;

   while (currentEnd < length) {
      currentLastIndex++;
      InfiniteScrollViewCell *cell = [self.dataSource infiniteScrollView:self cellForIndex:currentLastIndex];
      cell.index = currentLastIndex;
      [scrollView addSubview:cell];
      [visibleCells addObject:cell];

      if (!cachedCells[cell.identifier]) {
         cachedCells[cell.identifier] = [NSMutableSet set];
      }

      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         cell.frame = CGRectMake(cell.frame.origin.x, offset+currentEnd, cell.frame.size.width, cell.frame.size.height);
         currentEnd += cell.frame.size.height;
      } else {
         cell.frame = CGRectMake(offset+currentEnd, cell.frame.origin.y  , cell.frame.size.width, cell.frame.size.height);
         currentEnd += cell.frame.size.width;
      }
   }

   if (self.orientation == InfiniteScrollViewOrientationVertical) {
      scrollView.contentSize = CGSizeMake(self.frame.size.width, offset+currentEnd+offset);
      scrollView.contentOffset = CGPointMake(0, offset);
   } else {
      scrollView.contentSize = CGSizeMake(offset+currentEnd+offset, self.frame.size.height);
      scrollView.contentOffset = CGPointMake(offset, 0);
   }
}

-(InfiniteScrollViewCell*)dequeueReusableCellWithIdentifier:(NSString*)identifier
{
   if (cachedCells[identifier]) {
      InfiniteScrollViewCell *cell = [cachedCells[identifier] anyObject];
      if (cell) {
         [cachedCells[identifier] removeObject:cell];
         return cell;
      }
   }
   return nil;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView_
{
   float selfBegin = self.orientation == InfiniteScrollViewOrientationVertical? scrollView.contentOffset.y : scrollView.contentOffset.x;
   float selfEnd = selfBegin + (self.orientation == InfiniteScrollViewOrientationVertical? scrollView.frame.size.height : scrollView.frame.size.width);

   NSArray *copy = [NSArray arrayWithArray:visibleCells];

   for (InfiniteScrollViewCell *cell in copy) {
      float cellBegin = self.orientation == InfiniteScrollViewOrientationVertical? cell.frame.origin.y : cell.frame.origin.x;
      float cellEnd = cellBegin + (self.orientation == InfiniteScrollViewOrientationVertical? cell.frame.size.height : cell.frame.size.width);


      if (cellEnd < selfBegin || cellBegin > selfEnd) {
         [cell removeFromSuperview];
         [visibleCells removeObject:cell];
         [cachedCells[cell.identifier] addObject:cell];
      }
   }

   InfiniteScrollViewCell *firstCell = (InfiniteScrollViewCell*)[visibleCells firstObject];
   float firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y : firstCell.frame.origin.x;

   while (firstBegin > selfBegin) {
      int index = ((InfiniteScrollViewCell*)[visibleCells firstObject]).index-1;
      InfiniteScrollViewCell *cell = [self.dataSource infiniteScrollView:self cellForIndex:index];
      cell.index = index;
      [scrollView addSubview:cell];
      [visibleCells insertObject:cell atIndex:0];

      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         cell.frame = CGRectMake(cell.frame.origin.x, firstBegin-cell.frame.size.height, cell.frame.size.width, cell.frame.size.height);
      } else {
         cell.frame = CGRectMake(firstBegin-cell.frame.size.width, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
      }

      firstCell = (InfiniteScrollViewCell*)[visibleCells firstObject];
      firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y : firstCell.frame.origin.x;
   }

   firstCell = (InfiniteScrollViewCell*)[visibleCells lastObject];
   firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y + firstCell.frame.size.height : firstCell.frame.origin.x + firstCell.frame.size.width;

   while (firstBegin < selfEnd) {
      int index = ((InfiniteScrollViewCell*)[visibleCells lastObject]).index+1;
      InfiniteScrollViewCell *cell = [self.dataSource infiniteScrollView:self cellForIndex:index];
      cell.index = index;
      [scrollView addSubview:cell];
      [visibleCells addObject:cell];

      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         cell.frame = CGRectMake(cell.frame.origin.x, firstBegin, cell.frame.size.width, cell.frame.size.height);
      } else {
         cell.frame = CGRectMake(firstBegin, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
      }

      firstCell = (InfiniteScrollViewCell*)[visibleCells lastObject];
      firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y + firstCell.frame.size.height : firstCell.frame.origin.x + firstCell.frame.size.width;
   }

   if (selfBegin < kEndZoneLength) {
      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         float diff = scrollView.contentSize.height/2.0f - selfBegin;

         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y + diff, cell.frame.size.width, cell.frame.size.height);
         }
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y + diff);
         scrollView.delegate = self;
      } else {
         float diff = scrollView.contentSize.width/2.0f - selfBegin;

         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x + diff, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
         }
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x + diff, 0);
         scrollView.delegate = self;
      }
   }

   float length = self.orientation == InfiniteScrollViewOrientationVertical? scrollView.contentSize.height : scrollView.contentSize.width;
   if (selfEnd > length - kEndZoneLength) {
      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         float diff = scrollView.contentSize.height/2.0f - selfEnd;

         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y + diff, cell.frame.size.width, cell.frame.size.height);
         }
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y + diff);
         scrollView.delegate = self;
      } else {
         float diff = scrollView.contentSize.width/2.0f - selfEnd;

         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x + diff, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
         }
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x + diff, 0);
         scrollView.delegate = self;
      }
   }
}

-(int)firstVisibleIndex
{
   return ((InfiniteScrollViewCell*)[visibleCells firstObject]).index;
}

-(int)lastVisibleIndex
{
   return ((InfiniteScrollViewCell*)[visibleCells lastObject]).index;
}

-(NSArray*)visibleCells
{
   return [NSArray arrayWithArray:visibleCells];
}

@end
