//
//  CameraViewController.m
//  Ribbit
//
//  Created by Luke on 19/05/2014.
//  Copyright (c) 2014 Ceenos. All rights reserved.
//

#import "CameraViewController.h"

// obtain constant values of media types
#import <MobileCoreServices/UTCoreTypes.h>

@interface CameraViewController ()

@end

@implementation CameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.friendsRelation = [[PFUser currentUser] objectForKey:@"friendsRelation"];
    self.recipients = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    #pragma mark - Friends List Query
    
    PFQuery *query = [self.friendsRelation query];
    [query orderByAscending:@"username"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error %@ %@", error, [error userInfo]);
        } else {
            self.friends = objects;
            [self.tableView reloadData];
        }
    }];
    
    #pragma mark - Setup camera
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    
    // tell imagePicker that CameraViewController is its delegate
    self.imagePicker.delegate = self;
    
    // requires memory management
    self.imagePicker.allowsEditing = NO;
    
    // set maximum duration of videos
    self.imagePicker.videoMaximumDuration = 10; // 10 seconds
    
    // convenience method to check if camera is available
    // otherwise setting source type to camera does not work with simulator
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    // use source type just set
    self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePicker.sourceType];
    
    #pragma mark - Present camera modally
    
    [self presentViewController:self.imagePicker animated:NO completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // simply want to display username of each friend
    
    PFUser *user = [self.friends objectAtIndex:indexPath.row];
    cell.textLabel.text = user.username;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    // get current Users index using the indexPath to efficiently refer to user when handling requests with Parse.com
    PFUser *user = [self.friends objectAtIndex:indexPath.row];
    
    // toggle the checkmark
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.recipients addObject:user.objectId];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.recipients removeObject:user.objectId];
    }
    
    // print the array of recipients to test
    NSLog(@"%@", self.recipients);
}

#pragma mark - Image Picker Controller delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    // dismiss view controller presented modally
    [self dismissViewControllerAnimated:NO completion:nil];
    
    // return user back to the inbox tab
    // select inbox tab index array from TabBarController using setSelectedIndex
    [self.tabBarController setSelectedIndex:0];
}

// information stored in NSDictionary with 'info' key (shown below)
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // create variable to hold media type
    // so we can inspect media type string variable
    // different media types stored as constants as part of the Mobile Core Services Framework #imported rather than hard coded
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    // convert Core Foundation (CF) String to Next Step (NS) String counterpart (different type of string data structure) with a simple cast (NSString *) infront of kU...
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        // photo taken or selected
        
        // use @property in header file used for storing image for use throughout the rest of the view controller
        // set (where the image is in the NSDictionary with the 'info' key)
        self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        // check that camera itself is being used before storing
        if (self.imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            // save image using special function from UIKit Framework
            UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
        }
    } else {
        // video taken on selected
        // when a video is captured, it is stored in iOS internal path. reference with a key that is stored in the NSDictionary. movie file itself is not stored in the info NSDictionary use @property created in header file to store
        // pass in constant UIImagePickerControllerMediaURL
        // call the path method on this URL to get the local iOS path as a string
        self.videoFilePath = (__bridge NSString *)([[info objectForKey:UIImagePickerControllerMediaURL] path]);
        // allow ability to save the video to the photo album
        // check app will work on all devices
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.videoFilePath)) {
            UISaveVideoAtPathToSavedPhotosAlbum(self.videoFilePath, nil, nil, nil);
        }
        // limit size of file to store so app works fast. Parse.com has limit of 10mb for free account
        
    }
    // dismiss modal view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
