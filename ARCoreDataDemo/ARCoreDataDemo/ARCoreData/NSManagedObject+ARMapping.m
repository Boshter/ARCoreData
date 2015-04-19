//
//  NSManagedObject+ARMapping.m
//  Board
//
//  Created by August on 15/1/26.
//
//

#import "NSManagedObject+ARMapping.h"
#import "NSManagedObject+ARFetch.h"
#import "NSManagedObject+ARCreate.h"
#import "NSManagedObject+ARManageObjectContext.h"
#import "NSManagedObject+ARRequest.h"
#import "NSManagedObject+ARCreate.h"

@implementation NSManagedObject (ARMapping)

//+(NSMutableDictionary *)cacheLocalObjects
//{
//    static NSMutableDictionary *localObjects = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        localObjects = [NSMutableDictionary dictionary];
//    });
//    
//    return localObjects;
//}
//
//#pragma mark - transfrom methods
//
//+(id)fillWithJSON:(NSDictionary *)JSON
//{
//    if (JSON != nil) {
//        return [[self fillWithJSONs:@[JSON]] lastObject];
//    }
//    return nil;
//}
//
//+(NSArray *)fillWithJSONs:(NSArray *)JSONs
//{
//    NSAssert([JSONs isKindOfClass:[NSArray class]], @"JSONs should be a NSArray");
//    NSAssert1([self respondsToSelector:@selector(JSONKeyPathsByPropertyKey)],  @"%@ class should impliment +(NSDictionary *)JSONKeyPathsByPropertyKey; method", NSStringFromClass(self));
//    NSMutableArray *objs = [NSMutableArray array];
//    
//    NSDictionary *mapping = [self performSelector:@selector(JSONKeyPathsByPropertyKey)];
//    NSString *primaryKey = nil;
//    if ([self respondsToSelector:@selector(primaryKey)]) {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        primaryKey = [self performSelector:@selector(primaryKey)];
//#pragma clang diagnostic pop
//    }
//    
//    NSManagedObjectContext *context = [self defaultPrivateContext];
//    for (NSDictionary *JSON in JSONs) {
//        [objs addObject:[self objectWithJSON:JSON
//                                  primaryKey:primaryKey
//                                     mapping:mapping
//                                   inContext:context]];
//    
//    }
//    [[self cacheLocalObjects] removeAllObjects];
//    return objs;
//}

-(void)mergeAttributeForKey:(NSString *)attributeName withValue:(id)value
{
    NSAttributeDescription *attributeDes = [self attributeDescriptionForAttribute:attributeName];
    
    if (value != nil && value != [NSNull null]) {
        switch (attributeDes.attributeType) {
            case NSDecimalAttributeType:
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
            case NSDoubleAttributeType:
            case NSFloatAttributeType:
                [self setValue:numberFromString([value description]) forKey:attributeName];
                break;
            case NSBooleanAttributeType:
                [self setValue:[NSNumber numberWithBool:[value boolValue]] forKey:attributeName];
                break;
            case NSDateAttributeType:
                [self setValue:dateFromString(value) forKey:attributeName];
            case NSObjectIDAttributeType:
            case NSBinaryDataAttributeType:
            case NSStringAttributeType:
                [self setValue:[NSString stringWithFormat:@"%@",value] forKey:attributeName];
                break;
            case NSTransformableAttributeType:
            case NSUndefinedAttributeType:
                break;
            default:
                break;
        }
    }

}

-(void)mergeRelationshipForKey:(NSString *)relationshipName withValue:(id)value
{
    if (value == nil || [value isEqual:[NSNull null]]) {
        return;
    }
    NSRelationshipDescription *relationshipDes = [self relationshipDescriptionForRelationship:relationshipName];
    NSString *desClassName = relationshipDes.destinationEntity.managedObjectClassName;
    if (relationshipDes.isToMany) {
        NSArray *destinationObjs = [NSClassFromString(desClassName) AR_newOrUpdateWithJSONs:value];
        NSMutableSet *localSet = [self mutableSetValueForKey:relationshipName];
        if (destinationObjs != nil && destinationObjs.count > 0) {
            [localSet addObjectsFromArray:destinationObjs];
            [self setValue:localSet forKey:relationshipName];
        }
    }else{
        id destinationObjs = [NSClassFromString(desClassName) AR_newOrUpdateWithJSON:value];
        [self setValue:destinationObjs forKey:relationshipName];
    }

}

#pragma mark - 

-(NSAttributeDescription *)attributeDescriptionForAttribute:(NSString *)attributeName
{
    return [self.entity.attributesByName objectForKey:attributeName];
}

-(NSRelationshipDescription *)relationshipDescriptionForRelationship:(NSString *)relationshipName
{
    return [self.entity.relationshipsByName objectForKey:relationshipName];
}

#pragma mark - transform methods

NSDate * dateFromString(NSString *value)
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];
    
    NSDate *parsedDate = [formatter dateFromString:value];
    
    return parsedDate;
}

NSNumber * numberFromString(NSString *value) {
    return [NSNumber numberWithDouble:[value doubleValue]];
}

@end
