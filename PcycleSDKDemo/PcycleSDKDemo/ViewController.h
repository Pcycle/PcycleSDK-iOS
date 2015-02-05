//
//  ViewController.h
//  PcycleSDKDemo
//
//  Created by Arthur on 15/2/4.
//  Copyright (c) 2015年 FlyingFrog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PcycleSDK/PcycleSDK.h>

@interface ViewController : UIViewController<PcycleSDKDelegate>
{
    PcycleSDK *_pcycleSDK;
}

@property (nonatomic, retain) IBOutlet UIButton     *scanBtn;
@property (nonatomic, retain) IBOutlet UIButton     *connectBtn;
@property (nonatomic, retain) IBOutlet UILabel      *nameLbl;
@property (nonatomic, retain) IBOutlet UILabel      *uuidLbl;
@property (nonatomic, retain) IBOutlet UILabel      *rssiLbl;

@property (nonatomic, retain) IBOutlet UIView       *opView;
@property (nonatomic, retain) IBOutlet UIButton     *reqVelocityBtn;
@property (nonatomic, retain) IBOutlet UIButton     *setRBtn;
@property (nonatomic, retain) IBOutlet UILabel      *velocityLbl;
@property (nonatomic, retain) IBOutlet UILabel      *rollStateLbl;
@property (nonatomic, retain) IBOutlet UILabel      *btnStateLbl;
@property (nonatomic, retain) IBOutlet UITextField  *reText;
@property (nonatomic, retain) IBOutlet UIButton     *conReqBtn;

@end

