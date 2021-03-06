//
//  ViewController.m
//  PcycleSDKDemo
//
//  Created by Arthur on 15/2/4.
//  Copyright (c) 2015年 FlyingFrog. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

NSTimer *timer;
NSTimer *reTimer;
BOOL flag = YES;

int count = 0;

int circle[] = {0, 20, 40, 60, 80, 60, 40, 20};

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _pcycleSDK = [[PcycleSDK alloc] initWithDelegate:self];
    
    
    [self.scanBtn setTitle:@"开始扫描" forState:UIControlStateNormal];
    [self.connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    [self.conReqBtn setTitle:@"0.2s请求" forState:UIControlStateNormal];
    [self.setRBtn setTitle:@"2s连续" forState:UIControlStateNormal];
    [self.connectBtn setHidden:YES];
    [self.opView setHidden:YES];
    
    self.nameLbl.text = @"";
    self.uuidLbl.text = @"";
    self.rssiLbl.text = @"";
    self.stepFreqLbl.text = @"";

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updateValue:(id)sender
{
    float f = _slider.value;
    
    _reLbl.text = [NSString stringWithFormat:@"%.1f", f];
}

- (IBAction)editingDidEnd:(id)sender
{
    float f = _slider.value;
    
    [_pcycleSDK setResistance:f];
}

- (IBAction)scanBtnTouchUpInside:(id)sender
{
    if ([self.connectBtn.titleLabel.text isEqual:@"连接"])
    {
        if ([self.scanBtn.titleLabel.text isEqual:@"开始扫描"])
        {
            [_pcycleSDK scanForPcycleDevices];
            [self.scanBtn setTitle:@"停止扫描" forState:UIControlStateNormal];
        }
        else
        {
            [_pcycleSDK stopScan];
            [self.scanBtn setTitle:@"开始扫描" forState:UIControlStateNormal];
        }
    }
}

- (IBAction)connectBtnTouchUpInside:(id)sender
{
    if ([self.connectBtn.titleLabel.text isEqual:@"连接"])
    {
        [_pcycleSDK connectToPcycleDevice:self.uuidLbl.text];
        [_pcycleSDK stopScan];
        [self.scanBtn setTitle:@"开始扫描" forState:UIControlStateNormal];
    }
    else
    {
        [_pcycleSDK disconnectPcycleDevice:self.uuidLbl.text];
        [self.connectBtn setTitle:@"连接" forState:UIControlStateNormal];
        [self.opView setHidden:YES];
        
        
        [self.conReqBtn setTitle:@"0.2s请求" forState:UIControlStateNormal];
        [self.setRBtn setTitle:@"2s连续" forState:UIControlStateNormal];
        
        self.nameLbl.text = @"";
        self.uuidLbl.text = @"";
        self.rssiLbl.text = @"";
        self.stepFreqLbl.text = @"";
        self.btnStateLbl.text = @"";
        self.rollStateLbl.text = @"";
        
        [timer invalidate];
        [reTimer invalidate];
    }
}

- (void) conVelocityReq
{
    [_pcycleSDK requestCurrentVelocity];
}

- (IBAction)reqVolcityBtnTouchUpInside:(id)sender
{
    [_pcycleSDK requestCurrentVelocity];
}

- (IBAction)reqStepFreqBtnTouchUpInside:(id)sender
{
    [_pcycleSDK requestStepFreq];
}

- (IBAction)setRBtnTouchUpInside:(id)sender
{
    if ([self.setRBtn.titleLabel.text isEqual:@"2s连续"])
    {
        reTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(conSetR) userInfo:nil repeats:YES];
        
        [self.setRBtn setTitle:@"停止" forState:UIControlStateNormal];
        
  
    }
    else
    {
        [reTimer invalidate];
        [self.setRBtn setTitle:@"2s连续" forState:UIControlStateNormal];

    }
}

- (IBAction)conReqBtnTouchUpInside:(id)sender
{
    
    if ([self.conReqBtn.titleLabel.text isEqual:@"0.2s请求"])
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(conReq) userInfo:nil repeats:YES];
        
        [self.conReqBtn setTitle:@"停止" forState:UIControlStateNormal];
        
        [self.reqVelocityBtn setEnabled:NO];
    }
    else
    {
        [timer invalidate];
        [self.conReqBtn setTitle:@"0.2s请求" forState:UIControlStateNormal];
        [self.reqVelocityBtn setEnabled:YES];
    }
}

- (void)conSetR
{
    if (count > 7)
    {
        count = 0;
    }
    
    [_pcycleSDK setResistance:circle[count++]];
}

- (void)conReq
{
#if 1
    
        if (flag == YES)
        {
            [self conVelocityReq];
            flag = NO;
        }
        else
        {
            [_pcycleSDK requestStepFreq];
            flag = YES;
        }
    
#else
    [self conVelocityReq];
#endif
}

#pragma mark - PcycleSDKDelegate

-(void) pcycleSDK:(PcycleSDK *) pcycleSDK discoverPcycleDevice:(NSString *)name UUID:(NSString *)uuid RSSI:(NSNumber *)RSSI
{
    self.nameLbl.text = name;
    self.uuidLbl.text = uuid;
    self.rssiLbl.text = [NSString stringWithFormat:@"%@", RSSI];
    [self.connectBtn setHidden:NO];
}

-(void) pcycleSDK:(PcycleSDK *)pcycleSDK didConnectToPcycleDevice:(NSString *)name UUID:(NSString *)uuid error:(NSError *)error
{
    UIAlertView *alert;
    NSString *message;
    NSString *title;
    
    if (error != nil)
    {
        message = [NSString stringWithFormat:@"Error : %@", error.description];
        title = @"Error";
    }
    else
    {
        message = [NSString stringWithFormat:@"Successfully connect to %@", uuid];
        title = @"Success";
        
        [self.connectBtn setTitle:@"断开" forState:UIControlStateNormal];
        
        
        [self.opView setHidden:NO];
    }
    
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
}

- (void)pcycleSDK:(PcycleSDK *)pcycleSDK didDisconnectToPcycleDevice:(NSString *)name UUID:(NSString *)uuid error:(NSError *)error
{
    UIAlertView *alert;
    NSString *message;
    
    if (error != nil)
    {
        message = [NSString stringWithFormat:@"Error : %@", error.description];
    }
    else
    {
        message = [NSString stringWithFormat:@" disconnect to %@", uuid];
    }
    
    alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
}

-(void) pcycleSDK:(PcycleSDK *)pcycleSDK didRequestCurrentVelocity:(float)metersPerSecond error:(NSError *)error
{
    if (error == nil)
    {
        int x = (int)metersPerSecond;
        float n = (metersPerSecond - x) * 10;
        int m = (int)n;
        
        NSString *tmp = [NSString stringWithFormat:@"%d.%d m/s", x, m];
        
        if (x > 0 || (x == 0 && m > 0))
            NSLog(@"speed = %@", tmp);
        
        self.velocityLbl.text = [NSString stringWithFormat:@"%d.%d m/s", x, m];
    }
}

-(void) pcycleSDK:(PcycleSDK *)pcycleSDK didSetResistance:(float)newton error:(NSError *)error
{
    
}

- (void)pcycleSDK:(PcycleSDK *)pcycleSDK didRequestStepFreq:(float)cirlesPerMinute error:(NSError *)error
{
    if (error == nil)
    {
        int x = (int)cirlesPerMinute;
        float n = (cirlesPerMinute - x) * 10;
        int m = (int)n;
        
        NSString *tmp = [NSString stringWithFormat:@"%d.%d c/m", x, m];
        
        if (x > 0 || (x == 0 && m > 0))
            NSLog(@"freq  = %@", tmp);
        
        self.stepFreqLbl.text = tmp;
    }
    
}

-(void) pcycleSDK:(PcycleSDK *)pcycleSDK rollStickRolled:(PcycleRollStickAction)action error:(NSError *)error
{
    switch (action) {
            
        case PcycleRollStickActionUp:
            self.rollStateLbl.text = @"Up";
            break;
            
        case PcycleRollStickActionDown:
            self.rollStateLbl.text = @"Down";
            break;
            
        case PcycleRollStickActionLeft:
            self.rollStateLbl.text = @"Left";
            break;
            
        case PcycleRollStickActionRight:
            self.rollStateLbl.text = @"Right";
            break;
            
        case PcycleRollStickActionLeftUp:
            self.rollStateLbl.text = @"Left-Up";
            break;
            
        case PcycleRollStickActionLeftDown:
            self.rollStateLbl.text = @"Left-Down";
            break;
            
        case PcycleRollStickActionRightUp:
            self.rollStateLbl.text = @"Right-Up";
            break;
            
        case PcycleRollStickActionRightDown:
            self.rollStateLbl.text = @"Right-Down";
            break;
            
        default:
            self.rollStateLbl.text = @"";
            break;
    }
}

-(void) pcycleSDK:(PcycleSDK *)pcycleSDK buttonPressed:(NSNumber *)buttonIndex error:(NSError *)error
{
    self.btnStateLbl.text = [NSString stringWithFormat:@"Button %@", buttonIndex];
}

- (void)pcycleSDK:(PcycleSDK *)pcycleSDK didInit:(CBCentralManagerState)state
{
    NSLog(@"state = %ld", (long)state);
}

@end












