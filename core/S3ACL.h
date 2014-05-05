//
//  S3ACL.h
//  S3-Objc
//
//  Created by Bruce Chen on 4/23/06.
//  Modernized by Martin Hering on 07/14/12
//  Copyright 2014 Bruce Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, S3Permission) {
	S3READ_Permission
};

/*
@interface S3Grantee : NSObject
@end

@interface S3CanonicalUserGrantee : NSObject
@property (nonatomic) NSString* userId;
@property (nonatomic) NSString* displayName;
@end

@interface S3EmailGrantee : NSObject {
	NSString* _email;
}
+(S3EmailGrantee*)emailGranteeWithAddress:(NSString*)email;
@end

@interface S3GroupGrantee : NSObject {
	NSString* _id;
}
+(S3GroupGrantee*)allUsersGroupGrantee;
+(S3GroupGrantee*)allAuthenticatedUsersGroupGrantee;
@end

@interface S3OwnerGrantee : NSObject {
	NSString* _id;
}
+(S3OwnerGrantee*)ownerGranteeWithID:(NSString*)uid;
@end


@interface S3Grant : NSObject {
	S3Grantee* _grantee;
	S3Permission _permission;
}

@end
*/

@interface S3ACL : NSObject
@property (nonatomic) NSString* owner;
@property (nonatomic) NSMutableArray* accessList;
@end

/*
 
 getACLTemplatePublicReadWrite
 
 <?xml version="1.0" encoding="UTF-8"?>
 <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2014-03-01/">
 <Owner>
 <ID>selfId</ID>
 </Owner>
 <AccessControlList>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
 <ID>selfId</ID>
 <DisplayName>duspense</DisplayName>
 </Grantee>
 <Permission>FULL_CONTROL</Permission>
 </Grant>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
 <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
 </Grantee>
 <Permission>READ</Permission>
 </Grant>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
 <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
 </Grantee>
 <Permission>WRITE</Permission>
 </Grant>
 </AccessControlList>
 </AccessControlPolicy>
 
 getACLTemplatePrivate
 
 <?xml version="1.0" encoding="UTF-8"?>
 <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2014-03-01/">
 <Owner>
 <ID>selfId</ID>
 </Owner>
 <AccessControlList>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
 <ID>selfId</ID>
 </Grantee>
 <Permission>FULL_CONTROL</Permission>
 </Grant>
 </AccessControlList>
 </AccessControlPolicy>
 
 
 getACLTemplatePublicRead
 
 <?xml version="1.0" encoding="UTF-8"?>
 <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2014-03-01/">
 <Owner>
 <ID>selfId</ID>
 </Owner>
 <AccessControlList>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
 <ID>selfId</ID>
 </Grantee>
 <Permission>FULL_CONTROL</Permission>
 </Grant>
 <Grant>
 <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="Group">
 <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
 </Grantee>
 <Permission>READ</Permission>
 </Grant>
 </AccessControlList>
 </AccessControlPolicy>

 */