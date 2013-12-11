//
//  InfiniteScrollView.h
//  test
//
//  Created by Denis Stadniczuk on 11/12/13.
//  Copyright (c) 2013 Denis Stadniczuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfiniteScrollViewCell : UIView

-(id)initWithIdentifier:(NSString*)identifier;

@property (readwrite, strong, nonatomic) NSString *identifier;
@property (readwrite, nonatomic) int index;

@end


@class InfiniteScrollView;

@protocol InfiniteScrollViewDelegate <NSObject>

@end


@protocol InfiniteScrollViewDataSource <NSObject>

-(InfiniteScrollViewCell*)infiniteScrollView:(InfiniteScrollView*)scrollView cellForIndex:(int)index;

@end


enum InfiniteScrollViewOrientation {
   InfiniteScrollViewOrientationHorizontal,
   InfiniteScrollViewOrientationVertical
};

@interface InfiniteScrollView : UIView

-(void)reloadData;

-(InfiniteScrollViewCell*)dequeueReusableCellWithIdentifier:(NSString*)identifier;

@property (readwrite, nonatomic) enum InfiniteScrollViewOrientation orientation;
@property (readwrite, nonatomic, weak) id<InfiniteScrollViewDelegate> delegate;
@property (readwrite, nonatomic, weak) id<InfiniteScrollViewDataSource> dataSource;

-(int)firstVisibleIndex;
-(int)lastVisibleIndex;

-(NSArray*)visibleCells;

@end
