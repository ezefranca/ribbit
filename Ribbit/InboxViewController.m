//
//  InboxViewController.m
//  Ribbit
//
//  Created by Luke on 9/05/2014.
//  Copyright (c) 2014 Ceenos. All rights reserved.
//

// "" - search in current project for header file (i.e. project directory code)
#import "InboxViewController.h"

@interface InboxViewController ()

@end

@implementation InboxViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // check if user logged in. show login page only when user not logged in
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        NSLog(@"Current User: %@", currentUser.username);
    } else {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // query the new message class/table that we created in Parse.com database
    // only want list where our user id is in the list of recipient ids
    // (retrieve only messages sent to current user)
    // not want full list and then filter, as this is a waste of bandwidth and privacy issue
    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    // apply where clause condition
    [query whereKey:@"recipientIds" equalTo:[[PFUser currentUser] objectId]];
    [query orderByDescending:@"createdAt"];
    // execute query
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        } else {
            // where matching messages found and now stored in 'objects' array
            // and stored in @property defined in the header file. then use @property as
            // data source for table view
            self.messages = objects;
            // refresh table view
            [self.tableView reloadData];
            NSLog(@"Retrieved %d messages", [self.messages count]);
        }
    }];
    
    
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
    
    // count of data source
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // update Storyboard so prototype cell has identifier as 'Cell' also
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // username of person who sent the message, get message object that corresponds to
    // the row at this indexPath, where the message is a PFObject
    PFObject *message = [self.messages objectAtIndex:indexPath.row];
    
    // store senders username as 'senderName'
    cell.textLabel.text = [message objectForKey:@"senderName"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - IBActions

- (IBAction)logout:(id)sender {
    
    // log out user and take them back to the login page automatically calling login segue
    [PFUser logOut];
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // check identifer of segue incase there is more than one in view controller
    if ([segue.identifier isEqualToString:@"showLogin"]) {
        [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
    }
}

@end
