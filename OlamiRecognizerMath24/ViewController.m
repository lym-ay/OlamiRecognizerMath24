//
//  ViewController.m
//  OlamiReconginizer
//
//  Created by olami on 2017/4/24.
//  Copyright © 2017年 VIA Techologies, Inc. &OLAMI Team All rights reserved.
//  http://olami.ai

#import "ViewController.h"
#import "OlamiRecognizer.h"
#import "Math24.h"
#define OLACUSID   @"73D424AD-A85D-8163-52BB-F7515BFC3CBF"

@interface ViewController ()<OlamiRecognizerDelegate,UITextViewDelegate>{
    OlamiRecognizer *olamiRecognizer;
}
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UITextView *inputTextView;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;
@property (strong, nonatomic) NSMutableArray *slotValue;//保存slot的值
@property (strong, nonatomic) NSString *api;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupData];
    [self setupUI];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupUI {
    [_progressView setProgress:0.2];
    _recordBtn.layer.borderColor = [UIColor grayColor].CGColor;
    _recordBtn.layer.borderWidth = 1;
    _recordBtn.layer.cornerRadius = _recordBtn.frame.size.width/2;
    _recordBtn.layer.masksToBounds = YES;
}


- (void)setupData {
    // Do any additional setup after loading the view, typically from a nib.
    olamiRecognizer= [[OlamiRecognizer alloc] init];
    olamiRecognizer.delegate = self;
    [olamiRecognizer setAuthorization:@"d13bbcbef2a4460dbf19ced850eb5d83"
    api:@"asr" appSecret:@"3b08b349c0924a79869153bea334dd86" cusid:OLACUSID];
    
    [olamiRecognizer setLocalization:LANGUAGE_SIMPLIFIED_CHINESE];//设置语系，这个必须在录音使用之前初始化
  
    _inputTextView.delegate = self;
  
    _slotValue = [[NSMutableArray alloc] init];
}


- (IBAction)recordAtcion:(id)sender {
    [olamiRecognizer setInputType:0];
    if (olamiRecognizer.isRecording) {
        [olamiRecognizer stop];
        [_recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
        
    }else{
        [olamiRecognizer start];
        [_recordBtn setTitle:@"结束录音" forState:UIControlStateNormal];
    }

}

#pragma mark--NLU delegate
- (void)onUpdateVolume:(float)volume {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.progressView setProgress:(volume/100) animated:YES];
    });
}


- (void)onResult:(NSData *)result {
    NSError *error;
    __weak typeof(self) weakSelf = self;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:result
                        options:NSJSONReadingMutableContainers
                        error:&error];
    if (error) {
        NSLog(@"error is %@",error.localizedDescription);
    }else{
        NSString *jsonStr=[[NSString alloc]initWithData:result
                          encoding:NSUTF8StringEncoding];
        NSLog(@"jsonStr is %@",jsonStr);
        NSString *ok = [dic objectForKey:@"status"];
        if ([ok isEqualToString:@"ok"]) {
            NSDictionary *dicData = [dic objectForKey:@"data"];
            NSDictionary *asr = [dicData objectForKey:@"asr"];
            if (asr) {//如果asr不为空，说明目前是语音输入
                [weakSelf processASR:asr];
            }
            NSDictionary *nli = [[dicData objectForKey:@"nli"] objectAtIndex:0];
            NSDictionary *desc = [nli objectForKey:@"desc_obj"];
            int status = [[desc objectForKey:@"status"] intValue];
            if (status != 0) {// 0 说明状态正常,非零为状态不正常
                NSString *result  = [desc objectForKey:@"result"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _resultTextView.text = result;
                });
                
            }else{
                NSDictionary *semantic = [[nli objectForKey:@"semantic"]
                                         objectAtIndex:0];
                [weakSelf processSemantic:semantic];
                
            }
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                _resultTextView.text = @"请说出10以内的4个数";
            });
        }
    }
    
    
    
}

- (void)onEndOfSpeech {
    [_recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
}


- (void)onError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController
                                         alertControllerWithTitle:@"网络超时，请重试!"
                                         message:nil
                                         preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:^{
        dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC);
        dispatch_after(time, dispatch_get_main_queue(), ^{
            [alertController dismissViewControllerAnimated:YES completion:nil];
            
        });
        
    }];
    
    if (error) {
        NSLog(@"error is %@",error.localizedDescription);
    }

}


#pragma mark -- 处理语音和语义的结果
- (void)processModify:(NSString*) str {
    if ([str isEqualToString:@"play_want"]
        || [str isEqualToString:@"play_want_ask"]
        || [str isEqualToString:@"needmore"]
        || [str isEqualToString:@"needmore_ask"]) {//要求用户输入值
        dispatch_async(dispatch_get_main_queue(), ^{
            _resultTextView.text = @"请说出10以内的4个数";
        });
    }else if ([str isEqualToString:@"rules"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            _resultTextView.text = @"四个数字运算结果等于二十四";
        });
        
    }else if ([str isEqualToString:@"play_calculate"]){
        NSString* str = [[Math24 shareInstance] calculate:_slotValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            _resultTextView.text = str;
        });

    }else if ([str isEqualToString:@"attention"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            _resultTextView.text = @"四个数字必须是10以内的，不能超过10";
        });
    }
    
}

//处理ASR节点
- (void)processASR:(NSDictionary*)asrDic {
    NSString *result  = [asrDic objectForKey:@"result"];
    if (result.length == 0) { //如果结果为空，则弹出警告框
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"没有接受到语音，请重新输入!"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertController animated:YES completion:^{
            dispatch_time_t time=dispatch_time(DISPATCH_TIME_NOW, 1*NSEC_PER_SEC);
            dispatch_after(time, dispatch_get_main_queue(), ^{
                [alertController dismissViewControllerAnimated:YES completion:nil];
                
            });
            
        }];
        
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = [result stringByReplacingOccurrencesOfString:@" " withString:@""];//去掉字符中间的空格
            _inputTextView.text = str;
        });
    }

}

//处理Semantic节点
- (void)processSemantic:(NSDictionary*)semanticDic {
    NSArray *slot = [semanticDic objectForKey:@"slots"];
    [_slotValue removeAllObjects];
    if (slot.count != 0) {
        for (NSDictionary *dic in slot) {
            NSString* val = [dic objectForKey:@"value"];
            [_slotValue addObject:val];
        }
        
    }
    
    NSArray *modify = [semanticDic objectForKey:@"modifier"];
    if (modify.count != 0) {
        for (NSString *s in modify) {
            [self processModify:s];
            
        }
        
    }

}

#pragma mark--UITextView delegate
- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length != 0) {
        [olamiRecognizer setInputType:1];
        [olamiRecognizer sendText:textView.text];//发送文本到服务器
    }
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        
        [textView resignFirstResponder];//键盘消失
        
        return NO;
        
    }
    
    return YES;    
    
}

@end
