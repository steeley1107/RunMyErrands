//
//  DetailViewController.h
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-14.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Errand.h"


@interface DetailViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *errandNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *errandDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (nonatomic) Errand *errand;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *completeButton;


@end
