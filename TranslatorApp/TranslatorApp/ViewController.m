#import "ViewController.h"

#import "NSString+parsing.h"

#import "YandexTranslator.h"

#import "FileModel.h"

static NSString *const TranslatedPrefix = @"_translated";

@interface ViewController ()

@property (nonatomic) NSArray <FileModel *> *files;

@property (weak) IBOutlet NSTextField *startSymbolsTextField;
@property (weak) IBOutlet NSTextField *supportedFormatsTextField;

@property (weak) IBOutlet NSProgressIndicator *progress;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Actions
- (IBAction)translateAction:(id)sender
{
	NSURL *dirURL = [self getDirURL];
	
	//create copy item
	NSString *dirPath = [dirURL path];
	
	[self createDirectoryTreeWithDir:nil andOriginPath:dirPath];
	
	self.files = [self getFilesFromDirectory:dirPath];
	
	[self.progress setMinValue:0];
	[self.progress setMaxValue:self.files.count];
	
	for (FileModel *file in self.files) {
		
		NSMutableString *originFilePath = [NSMutableString stringWithString:file.originalPath];
		[originFilePath insertString:TranslatedPrefix atIndex:dirPath.length];
		
		file.translatedPath = [originFilePath copy];
		
		if (file.translatable) {
			[self translateFile:file];
		} else {
			[self copyFile:file];
		}
	}
}

- (void)updateProgress
{
	NSInteger translatedFileCount = 0;
	for (FileModel *file in self.files) {
		if (file.translated) {
			translatedFileCount++;
		}
	}
	
	[self.progress setDoubleValue:(double)translatedFileCount];
	
	if (translatedFileCount == self.files.count) {
		[NSApp terminate:self];
	}
}


- (NSArray *)startedStrings
{
	NSString *startSymbols = [self.startSymbolsTextField stringValue];
	
	NSArray *symbols = [startSymbols componentsSeparatedByString:@","];
	
	return symbols;
}

- (NSArray *)endedStrings
{
	return @[@"\n"];
}

- (NSArray *)supportedFileFormats
{
	NSString *supportedFormatsString = [self.supportedFormatsTextField stringValue];
	
	NSArray *supportedFormats = [supportedFormatsString componentsSeparatedByString:@","];
	
	return supportedFormats;
}

- (void)createDirectoryTreeWithDir:(NSString *)directoryPath andOriginPath:(NSString *)originPath
{
    NSString *translatedPath = [originPath stringByAppendingString:TranslatedPrefix];
    NSString *currentDirectoryPath;
    NSString *createdDirectoryPath;
    
    if (directoryPath) {
        currentDirectoryPath = [originPath stringByAppendingString:[NSString stringWithFormat:@"/%@", directoryPath]];
        createdDirectoryPath = [translatedPath stringByAppendingString:[NSString stringWithFormat:@"/%@", directoryPath]];

        NSError *fileCreationError = nil;
        [[self fileManager] createDirectoryAtPath:createdDirectoryPath withIntermediateDirectories:NO attributes:NO error:&fileCreationError];
    } else {
        currentDirectoryPath = originPath;
        createdDirectoryPath = translatedPath;
        
        NSError *fileCreationError = nil;
        [[self fileManager] createDirectoryAtPath:translatedPath withIntermediateDirectories:NO attributes:nil error:&fileCreationError];
    }
    
    NSError *contentError = nil;
    NSArray *dirContent = [[self fileManager] contentsOfDirectoryAtPath:currentDirectoryPath error:&contentError];
    
    if (contentError) {
        NSLog(@"content error: %@", contentError.localizedDescription);
    }
    
    for (NSString *fileName in dirContent) {
        NSString* fullFilePath = [currentDirectoryPath stringByAppendingPathComponent:fileName];
        NSString* shortFilePath;
        if (directoryPath) {
            shortFilePath = [directoryPath stringByAppendingPathComponent:fileName];
        } else {
            shortFilePath = fileName;
        }
        
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:fullFilePath isDirectory:&isDirectory];
        
        if (isDirectory) {
            [self createDirectoryTreeWithDir:[shortFilePath stringByAppendingString:@"/"] andOriginPath:originPath];
        }
    }
}

- (NSArray <FileModel *> *)getFilesFromDirectory:(NSString *)directoryPath
{
    NSMutableArray <FileModel *> *files = [NSMutableArray array];

    NSError *contentError = nil;
    NSArray *dirContent = [[self fileManager] contentsOfDirectoryAtPath:directoryPath error:&contentError];
    
    if (contentError) {
        NSLog(@"content error: %@", contentError.localizedDescription);
    }
    
    for (NSString *fileName in dirContent) {
        
        NSString* filePath = [directoryPath stringByAppendingPathComponent:fileName];
        
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        if (!isDirectory) {
            FileModel *file = [[FileModel alloc] init];
            file.originalPath = filePath;
            file.translatable = [self fileIsTranslatable:file];
			file.translated = NO;
            
            [files addObject:file];
            
        } else {
            NSArray <FileModel *> *filesInDir = [self getFilesFromDirectory:[filePath stringByAppendingString:@"/"]];
            [files addObjectsFromArray:filesInDir];
        }
    }
    return [files copy];
}

- (BOOL)fileIsTranslatable:(FileModel *)file
{
	NSArray *supportedFormats = [self supportedFileFormats];
    
    BOOL translatable = NO;
    
    for (NSString *format in supportedFormats) {
        NSString *finalSubstring = [file.originalPath substringFromIndex:(file.originalPath.length - format.length)];
        if ([finalSubstring isEqualToString:format]) {
            translatable = YES;
        }
    }
    
    return translatable;
}

- (NSFileManager *)fileManager
{
    static NSFileManager *manager;
    if (!manager) {
        manager = [NSFileManager defaultManager];
    }
    return manager;
}

- (void)translateFile:(FileModel *)file
{
    NSError *error = nil;
    NSString *contentString = [NSString stringWithContentsOfFile:file.originalPath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"riding error: %@", error.localizedDescription);
        [self copyFile:file];
        return;
    }
    
    NSArray <TranslatableStringModel *> *comments = [contentString substringsBetweenStartStrings:[self startedStrings] andEndStrings:[self endedStrings]];

    NSInteger __block requestsCount = 0;
    
    for (TranslatableStringModel *comment in comments) {
		
        requestsCount++;
        [[YandexTranslator sharedTranslator] getTranslationForString:comment
                                                             success:^{
                                                                 BOOL allCommentsTranslated = YES;
                                                                 for (TranslatableStringModel *comment in comments) {
                                                                     if (!comment.translated) {
                                                                         allCommentsTranslated = NO;
                                                                     }
                                                                 }
                                                                 if (allCommentsTranslated) {
                                                                     [self insertNewComments:comments inFile:file];
                                                                 }
                                                             }
                                                             failure:^(NSError *error) {
                                                                 NSLog(@"translated error: %@", error.localizedDescription);
                                                             }];
        
    }
    
    if (!comments.count) {
        [self copyFile:file];
    }

}

- (NSURL *)getDirURL
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    if ([panel runModal] != NSFileHandlingPanelOKButton) return nil;
    return [[panel URLs] lastObject];
}

- (void)insertNewComments:(NSArray *)comments inFile:(FileModel *)file
{
    NSError *error = nil;
    NSString *contentString = [NSString stringWithContentsOfFile:file.originalPath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"file content error: %@", error.localizedDescription);
    }
    
    NSMutableString *newContenString = [NSMutableString stringWithString:contentString];
    
    NSInteger shift = 0;

    for (TranslatableStringModel *comment in comments) {
        [newContenString deleteCharactersInRange:NSMakeRange(comment.loc - shift, comment.originalString.length)];
        [newContenString insertString:comment.translatedString atIndex:(comment.loc - shift)];
        
        shift += comment.originalString.length - comment.translatedString.length;
    }
    
    
    BOOL fileCreated = [[self fileManager] createFileAtPath:file.translatedPath contents:[newContenString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    if (!fileCreated) {
        NSLog(@"file doesn't created : %@", file.originalPath);
    } else {
		file.translated = YES;
		[self updateProgress];
    }
}

- (void)copyFile:(FileModel *)file
{
    NSError *copyError = nil;
    [[self fileManager] copyItemAtPath:file.originalPath toPath:file.translatedPath error:&copyError];
    
    if (copyError) {
        NSLog(@"copy error: %@", copyError);
    } else {
		file.translated = YES;
		[self updateProgress];
    }
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
}

@end
