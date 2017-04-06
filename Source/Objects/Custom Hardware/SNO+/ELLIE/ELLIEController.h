//
//  ELLIEController.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//  Revision history:
//  Ed Leming 04/01/2016 -  Removed global variables to move logic to
//                          ELLIEModel
//

#import <Foundation/Foundation.h>

@interface ELLIEController : OrcaObjectController <NSTextFieldDelegate>{

    //TAB Views
    IBOutlet NSTabView *ellieTabView;
    IBOutlet NSTabView *tellieTabView;
    IBOutlet NSTabView *tellieOperatorTabView;
    //TabViewItems
    IBOutlet NSTabViewItem *tellieTViewItem;
    IBOutlet NSTabViewItem *amellieTViewItem;
    IBOutlet NSTabViewItem *serversTViewItem;
    //TabViewItems
    IBOutlet NSTabViewItem *tellieFireFibreTViewItem;
    IBOutlet NSTabViewItem *tellieBuildConfigTViewItem;
    IBOutlet NSTabViewItem *tellieGeneralOpTViewItem;
    IBOutlet NSTabViewItem *tellieExpertOpTViewItem;
    
    //TELLIE interface ------------------------------------------
    
    ////////////////////
    //General interface
    IBOutlet NSTextField* tellieGeneralNodeTf;
    IBOutlet NSTextField* tellieGeneralPhotonsTf;
    IBOutlet NSTextField* tellieGeneralTriggerDelayTf;
    IBOutlet NSTextField *tellieGeneralNoPulsesTf;
    IBOutlet NSTextField *tellieGeneralFreqTf;

    IBOutlet NSPopUpButton* tellieGeneralFibreSelectPb;
    IBOutlet NSPopUpButton* tellieGeneralOperationModePb; //Operation mode (master or slave)
    
    IBOutlet NSButton *tellieGeneralFireButton;
    IBOutlet NSButton *tellieGeneralStopButton;
    IBOutlet NSButton *tellieGeneralValidateSettingsButton;
    
    IBOutlet NSTextField *tellieGeneralValidationStatusTf;
    
    ////////////////////
    //Expert interface
    IBOutlet NSTextField *tellieChannelTf;
    IBOutlet NSTextField *telliePulseWidthTf;
    IBOutlet NSTextField *telliePulseFreqTf;
    IBOutlet NSTextField *telliePulseHeightTf;
    IBOutlet NSTextField *tellieFibreDelayTf;
    IBOutlet NSTextField *tellieTriggerDelayTf;
    IBOutlet NSTextField *tellieNoPulsesTf;
    IBOutlet NSTextField *telliePhotonsTf;
    
    IBOutlet NSTextField *tellieExpertNodeTf;
    IBOutlet NSPopUpButton *tellieExpertFibreSelectPb;
    IBOutlet NSPopUpButton *tellieExpertOperationModePb; //Operation mode (master or slave)
    
    IBOutlet NSTextField *tellieExpertValidationStatusTf;
    
    IBOutlet NSButton *tellieExpertFireButton;
    IBOutlet NSButton *tellieExpertStopButton;
    IBOutlet NSButton *tellieExpertValidateSettingsButton;
   
    ////////////////////
    //Custom sequence
    IBOutlet NSMatrix *tellieBuildNodeSelection;
    IBOutlet NSTextField *tellieBuildPhotons;
    IBOutlet NSTextField *tellieBuildTrigDelay;

    IBOutlet NSTextField *tellieBuildNoPulses;
    IBOutlet NSTextField *tellieBuildRate;
    IBOutlet NSTextField *tellieBuildRunName;
    IBOutlet NSPopUpButton *tellieBuildOpMode;
    IBOutlet NSButton *tellieBuildValidate;
    IBOutlet NSButton *tellieBuildPushToDB;

    //Server interface ------------------------------------------

    IBOutlet NSTextField *tellieHostTf;
    IBOutlet NSTextField *smellieHostTf;
    IBOutlet NSTextField *interlockHostTf;

    IBOutlet NSTextField *telliePortTf;
    IBOutlet NSTextField *smelliePortTf;
    IBOutlet NSTextField *interlockPortTf;

    IBOutlet NSTextField *tellieServerResponseTf;
    IBOutlet NSTextField *smellieServerResponseTf;
    IBOutlet NSTextField *interlockServerResponseTf;

    // Instance variables
    NSThread *tellieThread;
    NSButton *tellieExpertConvertAction;
    NSWindowController* _nodeMapWC;
    NSMutableDictionary* _guiFireSettings;
    NSThread* _tellieThread;
    NSThread* _smellieThread;
    NSButton *interlockPing;
}

// Properties
@property (nonatomic,strong) NSWindowController* nodeMapWC;
@property (nonatomic,strong) NSMutableDictionary* guiFireSettings;
@property (nonatomic, strong) NSThread* tellieThread;
@property (nonatomic, strong) NSThread* smellieThread;

-(id)init;
-(void)dealloc;
-(void)updateWindow;
-(void)registerNotificationObservers;
-(void)awakeFromNib;
-(void)updateServerSettings:(NSNotification *)aNote;
-(BOOL)isNumeric:(NSString *)s;
-(void)fetchConfigurationFile:(NSNotification *)aNote;

//TELLIE functions -----------------------------

//General tab
-(IBAction)tellieGeneralValidateSettingsAction:(id)sender;
-(IBAction)tellieGeneralFireAction:(id)sender;
-(IBAction)tellieGeneralStopAction:(id)sender;
-(IBAction)tellieNodeMapAction:(id)sender;
-(IBAction)tellieGeneralFibreNameAction:(NSPopUpButton *)sender;
-(IBAction)tellieGeneralModeAction:(NSPopUpButton *)sender;


//Expert tab
-(IBAction)tellieExpertFireAction:(id)sender;
-(IBAction)tellieExpertStopAction:(id)sender;
-(IBAction)tellieExpertValidateSettingsAction:(id)sender;
-(IBAction)tellieExpertAutoFillAction:(id)sender;
-(IBAction)tellieExpertFibreNameAction:(NSPopUpButton *)sender;
-(IBAction)tellieExpertModeAction:(NSPopUpButton *)sender;

//Vaidation functions
-(NSString*)validateGeneralTellieNode:(NSString *)currentText;
-(NSString*)validateGeneralTelliePhotons:(NSString *)currentText;
-(NSString*)validateGeneralTellieTriggerDelay:(NSString *)currentText;
-(NSString*)validateGeneralTellieNoPulses:(NSString *)currentText;
-(NSString*)validateGeneralTelliePulseFreq:(NSString *)currentText;

//Expert gui
-(NSString*)validateTellieChannel:(NSString *)currentText;
-(NSString*)validateTelliePulseWidth:(NSString *)currentText;
-(NSString*)validateTelliePulseFreq:(NSString *)currentText;
-(NSString*)validateTelliePulseHeight:(NSString *)currentText;
-(NSString*)validateTellieFibreDelay:(NSString *)currentText;
-(NSString*)validateTellieTriggerDelay:(NSString *)currentText;
-(NSString*)validateTellieNoPulses:(NSString *)currentText;

-(void)tellieRunFinished:(NSNotification *)aNote;
-(void)initialiseTellie;
- (void) duplicateDialog:(id)dialog;

//Build Custom sequence
-(IBAction)tellieBuildValidateAction:(id)sender;
-(IBAction)tellieBuildPushToDBAction:(id)sender;


//Server tab functions -----------------------------
- (IBAction)telliePing:(id)sender;
- (IBAction)smelliePing:(id)sender;
- (IBAction)interlockPing:(id)sender;
- (IBAction) serverSettingsChanged:(id)sender;
-(void)killInterlock:(NSNotification *)aNote;

@end

extern NSString* ORTELLIERunStart;
extern NSString* ORSMELLIERunFinished;
extern NSString* ORTELLIERunFinished;

