InfiniteScrollView
==================

UITableView-like infinite scroll view for iOS. Supports horizontal and vertical orientation. It's pretty fast.

Use
===

    - (void)viewDidLoad
    {
        [super viewDidLoad];
        InfiniteScrollView *scrollView = [[InfiniteScrollView alloc] init];
        scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*0.5f);
        scrollView.orientation = InfiniteScrollViewOrientationVertical;
        [self.view addSubview:scrollView];
        scrollView.delegate = self;
        scrollView.dataSource = self;
    }


    -(InfiniteScrollViewCell*)infiniteScrollView:(InfiniteScrollView *)scrollView cellForIndex:(int)index
    {
       static NSString *identifier = @"test-cell";
       InfiniteScrollViewCell *cell = [scrollView dequeueReusableCellWithIdentifier:identifier];
       if (cell == nil) {
          cell = [[InfiniteScrollViewCell alloc] initWithIdentifier:identifier];
          // InfiniteScrollView uses this information for the location and size of the cell
          // The height of this cell will be 50 pixels
          // Set the width if your orientation is horizontal
          // The only value ignored here is the y position (or x position for horizontal orientation)
          cell.frame = CGRectMake(0, 0, self.view.frame.size.width, 50);
       }
      // customize the cell. Index 0 is the first cell displayed when loaded
      // positive indexes mean right/down, negative indexes left/up (depends on orientation)
       return cell;
    }
