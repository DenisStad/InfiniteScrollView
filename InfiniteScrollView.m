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

   CGPoint formerOffset;
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
   scrollView.frame = self.bounds; //maybe the frame changed, too, but this line might be unnecessary

   cachedCells = [NSMutableDictionary dictionary]; //remove all cached cells

   float currentEnd = 0;
   float length = self.orientation == InfiniteScrollViewOrientationVertical? self.frame.size.height : self.frame.size.width;
   float offset = kEndZoneLength + length*20;

   int currentLastIndex = -1;

   //fill the current frame so that we see something
   while (currentEnd < length) {
      currentLastIndex++;
      InfiniteScrollViewCell *cell = [self.dataSource infiniteScrollView:self cellForIndex:currentLastIndex];
      cell.index = currentLastIndex;
      [scrollView addSubview:cell];
      [visibleCells addObject:cell];

      //create cell caches at initialization, so we don't have to when we're scrolling
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

   //scroll to middle
   scrollView.delegate = nil;
   if (self.orientation == InfiniteScrollViewOrientationVertical) {
      scrollView.contentSize = CGSizeMake(self.frame.size.width, offset+currentEnd+offset);
      scrollView.contentOffset = CGPointMake(0, offset);
   } else {
      scrollView.contentSize = CGSizeMake(offset+currentEnd+offset, self.frame.size.height);
      scrollView.contentOffset = CGPointMake(offset, 0);
   }
   formerOffset = scrollView.contentOffset;
   scrollView.delegate = self;
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

-(void)removeCell:(InfiniteScrollViewCell*)cell
{
   [visibleCells removeObject:cell];
   [cachedCells[cell.identifier] addObject:cell];
   //move it out of the window
   if (self.orientation == InfiniteScrollViewOrientationVertical) {
      cell.frame = CGRectMake(cell.frame.origin.x, -cell.frame.size.height, cell.frame.size.width, cell.frame.size.height);
   } else {
      cell.frame = CGRectMake(-cell.frame.size.width, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
   }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView_
{
   float diff;
   if (self.orientation == InfiniteScrollViewOrientationHorizontal) {
      diff = scrollView.contentOffset.x - formerOffset.x;
   } else {
      diff = scrollView.contentOffset.y - formerOffset.y;
   }
   formerOffset = scrollView.contentOffset;

   float selfBegin = self.orientation == InfiniteScrollViewOrientationVertical? scrollView.contentOffset.y : scrollView.contentOffset.x;
   float length = self.orientation == InfiniteScrollViewOrientationVertical? scrollView.frame.size.height : scrollView.frame.size.width;
   float scrollLength = self.orientation == InfiniteScrollViewOrientationVertical? scrollView.contentSize.height : scrollView.contentSize.width;
   float selfEnd = selfBegin + length;

   if ( ((diff < 0) ? (-diff) : (diff))   > length ) {
      //we are scrolling very fast and since we can't see the content properly anyway,
      //we just estimate the current index and make sure that some cells are in the view

      float avgCellLength = 0; //calculate the avg cell length in order to estimte how many indices we jumped
      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         for (InfiniteScrollViewCell* cell  in visibleCells) {
            avgCellLength += cell.frame.size.height;
         }
      } else {
         for (InfiniteScrollViewCell* cell  in visibleCells) {
            avgCellLength += cell.frame.size.width;
         }
      }
      avgCellLength /= (float) visibleCells.count;
      int numIndices = roundf(diff / avgCellLength); //estimate

      InfiniteScrollViewCell *firstCell = [visibleCells firstObject];

      int firstIndex = firstCell.index + numIndices;
      //set the index to the estimated index
      //don't update the cells content, since we won't see it anyway and it might be costly
      firstCell.index = firstIndex;
      //set the frame of the cell to the current offset, just to be sure there something we see
      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         firstCell.frame = CGRectMake(firstCell.frame.origin.x, selfBegin, firstCell.frame.size.width, firstCell.frame.size.height);
      } else {
         firstCell.frame = CGRectMake(selfBegin, firstCell.frame.origin.y, firstCell.frame.size.width, firstCell.frame.size.height);
      }


      //remove all other cells
      for (int i = 1; i < visibleCells.count; i++) {
         InfiniteScrollViewCell *cell = visibleCells[i];
         [self removeCell:cell];
      }
      if ([self.delegate respondsToSelector:@selector(infiniteScrollViewDidScroll:)]) {
         [self.delegate infiniteScrollViewDidScroll:self];
      }
      return;
   }


   InfiniteScrollViewCell *firstCell = (InfiniteScrollViewCell*)[visibleCells firstObject];
   float firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y : firstCell.frame.origin.x;

   // check if there are cells missing at the beginning
   while (firstBegin > selfBegin) {
      int index = ((InfiniteScrollViewCell*)[visibleCells firstObject]).index-1;
      InfiniteScrollViewCell *cell = [self.dataSource infiniteScrollView:self cellForIndex:index];
      cell.index = index;
      if (!cell.superview) {
         [scrollView addSubview:cell];
      }
      [visibleCells insertObject:cell atIndex:0];

      //only add it if it's really visible
      if (firstBegin < selfEnd) {
         if (self.orientation == InfiniteScrollViewOrientationVertical) {
            cell.frame = CGRectMake(cell.frame.origin.x, firstBegin-cell.frame.size.height, cell.frame.size.width, cell.frame.size.height);
         } else {
            cell.frame = CGRectMake(firstBegin-cell.frame.size.width, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
         }
      }

      firstCell = (InfiniteScrollViewCell*)[visibleCells firstObject];
      firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y : firstCell.frame.origin.x;
   }

   firstCell = (InfiniteScrollViewCell*)[visibleCells lastObject];
   firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y + firstCell.frame.size.height : firstCell.frame.origin.x + firstCell.frame.size.width;

   //check if there are cells missing at the end
   while (firstBegin < selfEnd) {
      int index = ((InfiniteScrollViewCell*)[visibleCells lastObject]).index+1;
      InfiniteScrollViewCell *cell = [self.dataSource infiniteScrollView:self cellForIndex:index];
      cell.index = index;
      if (!cell.superview) {
         [scrollView addSubview:cell];
      }
      [visibleCells addObject:cell];

      //only add it if it's really visible
      if (firstBegin > selfBegin) {
         if (self.orientation == InfiniteScrollViewOrientationVertical) {
            cell.frame = CGRectMake(cell.frame.origin.x, firstBegin, cell.frame.size.width, cell.frame.size.height);
         } else {
            cell.frame = CGRectMake(firstBegin, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
         }
      }

      firstCell = (InfiniteScrollViewCell*)[visibleCells lastObject];
      firstBegin = self.orientation == InfiniteScrollViewOrientationVertical? firstCell.frame.origin.y + firstCell.frame.size.height : firstCell.frame.origin.x + firstCell.frame.size.width;
   }

   NSArray *copy = [NSArray arrayWithArray:visibleCells];

   for (InfiniteScrollViewCell *cell in copy) {
      float cellBegin = self.orientation == InfiniteScrollViewOrientationVertical? cell.frame.origin.y : cell.frame.origin.x;
      float cellEnd = cellBegin + (self.orientation == InfiniteScrollViewOrientationVertical? cell.frame.size.height : cell.frame.size.width);


      if (cellEnd < selfBegin || cellBegin > selfEnd) {
         [self removeCell:cell];
      }
   }

   //if we're near beginning, scroll to the middle
   if (selfBegin < kEndZoneLength) {
      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         float diff = scrollView.contentSize.height/2.0f - selfBegin;

         //move cells down
         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y + diff, cell.frame.size.width, cell.frame.size.height);
         }

         //set contentoffset
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y + diff);
         formerOffset = scrollView.contentOffset;
         scrollView.delegate = self;
      } else {
         float diff = scrollView.contentSize.width/2.0f - selfBegin;

         //move cells right
         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x + diff, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
         }

         //set contentoffset
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x + diff, 0);
         formerOffset = scrollView.contentOffset;
         scrollView.delegate = self;
      }
   }

   //if we're near end, scroll to the middle
   if (selfEnd > scrollLength - kEndZoneLength) {
      if (self.orientation == InfiniteScrollViewOrientationVertical) {
         float diff = scrollView.contentSize.height/2.0f - selfEnd;

         //move cells up
         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y + diff, cell.frame.size.width, cell.frame.size.height);
         }

         //set contentoffset
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y + diff);
         formerOffset = scrollView.contentOffset;
         scrollView.delegate = self;
      } else {
         float diff = scrollView.contentSize.width/2.0f - selfEnd;

         //move cells left
         for (InfiniteScrollViewCell *cell in visibleCells) {
            cell.frame = CGRectMake(cell.frame.origin.x + diff, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height);
         }

         //set contentoffset
         scrollView.delegate = nil;
         scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x + diff, 0);
         formerOffset = scrollView.contentOffset;
         scrollView.delegate = self;
      }
   }

   if ([self.delegate respondsToSelector:@selector(infiniteScrollViewDidScroll:)]) {
      [self.delegate infiniteScrollViewDidScroll:self];
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

-(CGPoint)contentOffset
{
   return scrollView.contentOffset;
}

@end
