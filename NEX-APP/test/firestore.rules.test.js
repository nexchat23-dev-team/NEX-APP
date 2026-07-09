const fs = require('fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');

const rules = fs.readFileSync('firestore.rules', 'utf8');

describe('Firestore rules (comprehensive tests)', function() {
  this.timeout(10000);
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'nex-app-test',
      firestore: { rules }
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  describe('User Profiles', () => {
    it('allows a user to create their own profile', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertSucceeds(db.collection('users').doc('alice-uid').set({
        uid: 'alice-uid',
        email: 'alice@example.com',
        createdAt: new Date()
      }));
    });

    it('prevents a user from creating another user profile', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertFails(db.collection('users').doc('bob-uid').set({
        uid: 'bob-uid',
        email: 'bob@example.com',
        createdAt: new Date()
      }));
    });
  });

  describe('User Profile Pictures', () => {
    it('allows user to upload their own profile picture', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      // First create user profile
      await assertSucceeds(db.collection('users').doc('alice-uid').set({
        uid: 'alice-uid',
        email: 'alice@example.com',
        createdAt: new Date()
      }));
      // Then upload profile picture
      await assertSucceeds(db.collection('userProfilePictures').doc('pic-1').set({
        userId: 'alice-uid',
        url: 'https://cdn.example.com/pic1.jpg',
        uploadedAt: new Date(),
        fileName: 'profile.jpg'
      }));
    });

    it('prevents user from uploading another user profile picture', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertFails(db.collection('userProfilePictures').doc('pic-2').set({
        userId: 'bob-uid',
        url: 'https://cdn.example.com/pic2.jpg',
        uploadedAt: new Date(),
        fileName: 'other.jpg'
      }));
    });

    it('allows authenticated users to read profile pictures', async () => {
      const bob = testEnv.authenticatedContext('bob-uid');
      const db = bob.firestore();
      // Bob should be able to read Alice's picture (if user exists)
      await testEnv.withSecurityRulesDisabled(async (context) => {
        // Setup: create user and picture with disabled rules
        await context.firestore().collection('users').doc('alice-uid').set({
          uid: 'alice-uid',
          email: 'alice@example.com',
          createdAt: new Date()
        });
        await context.firestore().collection('userProfilePictures').doc('pic-1').set({
          userId: 'alice-uid',
          url: 'https://cdn.example.com/pic1.jpg',
          uploadedAt: new Date(),
          fileName: 'profile.jpg'
        });
      });
      // Now Bob reads with security rules enabled
      await assertSucceeds(db.collection('userProfilePictures').doc('pic-1').get());
    });
  });

  describe('User Avatars', () => {
    it('allows user to create their own avatar record', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertSucceeds(db.collection('userAvatars').doc('alice-uid').set({
        userId: 'alice-uid',
        avatarUrl: 'https://cdn.example.com/avatar.jpg',
        backgroundColor: '#FF5733',
        createdAt: new Date(),
        updatedAt: new Date()
      }));
    });

    it('prevents user from creating avatar for another user', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertFails(db.collection('userAvatars').doc('bob-uid').set({
        userId: 'bob-uid',
        avatarUrl: 'https://cdn.example.com/avatar-bob.jpg',
        backgroundColor: '#00FF00',
        createdAt: new Date(),
        updatedAt: new Date()
      }));
    });

    it('allows authenticated user to read any avatar', async () => {
      const bob = testEnv.authenticatedContext('bob-uid');
      const db = bob.firestore();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('userAvatars').doc('alice-uid').set({
          userId: 'alice-uid',
          avatarUrl: 'https://cdn.example.com/avatar.jpg',
          backgroundColor: '#FF5733',
          createdAt: new Date(),
          updatedAt: new Date()
        });
      });
      await assertSucceeds(db.collection('userAvatars').doc('alice-uid').get());
    });
  });

  describe('Image Metadata', () => {
    it('allows user to store image metadata', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertSucceeds(db.collection('imageMetadata').doc('meta-1').set({
        userId: 'alice-uid',
        pictureId: 'pic-1',
        width: 1920,
        height: 1080,
        format: 'jpeg',
        createdAt: new Date()
      }));
    });

    it('rejects invalid image format', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertFails(db.collection('imageMetadata').doc('meta-2').set({
        userId: 'alice-uid',
        pictureId: 'pic-2',
        width: 800,
        height: 600,
        format: 'bmp',
        createdAt: new Date()
      }));
    });

    it('prevents user from storing metadata for another user', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertFails(db.collection('imageMetadata').doc('meta-3').set({
        userId: 'bob-uid',
        pictureId: 'pic-3',
        width: 640,
        height: 480,
        format: 'png',
        createdAt: new Date()
      }));
    });
  });

  describe('Profile Picture Versions', () => {
    it('allows user to create picture versions', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertSucceeds(db.collection('profilePictureVersions').doc('v-1').set({
        userId: 'alice-uid',
        pictureId: 'pic-1',
        size: 'thumbnail',
        url: 'https://cdn.example.com/pic-thumb.jpg',
        createdAt: new Date()
      }));
    });

    it('rejects invalid picture size', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertFails(db.collection('profilePictureVersions').doc('v-2').set({
        userId: 'alice-uid',
        pictureId: 'pic-1',
        size: 'xlarge',
        url: 'https://cdn.example.com/pic-xl.jpg',
        createdAt: new Date()
      }));
    });

    it('allows authenticated user to read picture versions', async () => {
      const bob = testEnv.authenticatedContext('bob-uid');
      const db = bob.firestore();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('profilePictureVersions').doc('v-1').set({
          userId: 'alice-uid',
          pictureId: 'pic-1',
          size: 'thumbnail',
          url: 'https://cdn.example.com/pic-thumb.jpg',
          createdAt: new Date()
        });
      });
      await assertSucceeds(db.collection('profilePictureVersions').doc('v-1').get());
    });
  });

  describe('Profile Pictures Index', () => {
    it('allows user to create index entry for their picture', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertSucceeds(db.collection('profilePicturesIndex').doc('idx-1').set({
        userId: 'alice-uid',
        pictureId: 'pic-1',
        indexedAt: new Date()
      }));
    });

    it('prevents user from indexing another user picture', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      const db = alice.firestore();
      await assertFails(db.collection('profilePicturesIndex').doc('idx-2').set({
        userId: 'bob-uid',
        pictureId: 'pic-2',
        indexedAt: new Date()
      }));
    });

    it('allows authenticated user to query index', async () => {
      const bob = testEnv.authenticatedContext('bob-uid');
      const db = bob.firestore();
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('profilePicturesIndex').doc('idx-1').set({
          userId: 'alice-uid',
          pictureId: 'pic-1',
          indexedAt: new Date()
        });
      });
      await assertSucceeds(db.collection('profilePicturesIndex').doc('idx-1').get());
    });
  });

  describe('Direct Conversations', () => {
    it('allows a participant to send a message to a direct conversation', async () => {
      const alice = testEnv.authenticatedContext('alice-uid');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('conversations').doc('direct-conv-1').set({
          createdBy: 'alice-uid',
          participants: ['alice-uid', 'bob-uid'],
          isGroup: false,
          groupName: null,
          admins: [],
          inviteCode: null,
          inviteLink: null,
          autoJoinEnabled: null,
          createdAt: new Date(),
          lastMessage: null,
          lastMessageTime: null,
        });
      });

      const db = alice.firestore();
      await assertSucceeds(db.collection('conversations').doc('direct-conv-1').collection('messages').doc('msg-1').set({
        senderId: 'alice-uid',
        text: 'Hello from Alice',
        timestamp: new Date(),
      }));
    });

    it('rejects a non-participant from sending a message to a direct conversation', async () => {
      const charlie = testEnv.authenticatedContext('charlie-uid');
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('conversations').doc('direct-conv-2').set({
          createdBy: 'alice-uid',
          participants: ['alice-uid', 'bob-uid'],
          isGroup: false,
          groupName: null,
          admins: [],
          inviteCode: null,
          inviteLink: null,
          autoJoinEnabled: null,
          createdAt: new Date(),
          lastMessage: null,
          lastMessageTime: null,
        });
      });

      const db = charlie.firestore();
      await assertFails(db.collection('conversations').doc('direct-conv-2').collection('messages').doc('msg-2').set({
        senderId: 'charlie-uid',
        text: 'Not allowed',
        timestamp: new Date(),
      }));
    });
  });

});
