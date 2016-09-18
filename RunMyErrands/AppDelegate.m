//
//  AppDelegate.m
//  RunMyErrands
//
//  Created by Jeff Mew on 2015-11-14.
//  Copyright © 2015 Jeff Mew. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "API_key.h"
#import "RunMyErrands-Swift.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "Errand.h"
//#import <ParseTwitterUtils/ParseTwitterUtils.h>

@import GooglePlaces;

@interface AppDelegate ()
@property (nonatomic) Scheduler *scheduler;
@property (nonatomic) ErrandManager *errandManager;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Parse
    [Errand registerSubclass];
    [Parse setApplicationId:PARSE_APP_ID
                  clientKey:PARSE_CLIENT_KEY];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    
    //Setup Notifications
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    //Facebook
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    //Twitter
    //[PFTwitterUtils initializeWithConsumerKey:TWITTER_CONSUMER_KEY
    //                           consumerSecret:TWITTER_CONSUMER_SECRET];
    
    //Google Maps
    [GMSServices provideAPIKey:GOOGLE_MAPS_KEY];
    [GMSPlacesClient provideAPIKey:GOOGLE_MAPS_KEY];
    
    
    //Use 'Login-signup' storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:[NSBundle mainBundle]];
    LoginViewController *vc =[storyboard instantiateInitialViewController];
    
    // Set root view controller and make windows visible
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    self.errandManager = [ErrandManager new];
    
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle: [NSString stringWithFormat:@"%@", notification.alertTitle]
                                  message:[NSString stringWithFormat:@"%@",notification.alertBody]
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:cancel];
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}


-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if([userInfo[@"aps"][@"content-available"] intValue]== 1) //it's the silent notification
    {
        //update errands from Parse
        [self.errandManager fetchData:^(BOOL success) {
            if (success) {
                
            }
        }];
        
        //bla bla bla put your code here
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    else
    {
        [PFPush handlePush:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pushUpdate" object:nil];
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
}


@end
