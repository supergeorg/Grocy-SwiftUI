//
//  UserFormView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 26.11.20.
//

import PhotosUI
import SwiftData
import SwiftUI

/// Creates or edits a user, like Grocy's user form: names, password, picture and the users' userfields.
///
/// Editing oneself needs the USERS_EDIT_SELF permission, editing others USERS_EDIT and creating users USERS_CREATE;
/// the server checks them and the form shows its answer.
struct UserFormView: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    @Query var users: GrocyUsers
    @Query private var systemConfigList: [SystemConfig]

    @Environment(\.dismiss) var dismiss

    @State private var username: String
    @State private var firstName: String
    @State private var lastName: String
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""

    /// A newly chosen picture as JPEG, uploaded on save.
    @State private var newPictureData: Data?
    @State private var pictureItem: PhotosPickerItem?
    /// The saved picture is removed on save.
    @State private var removesPicture: Bool = false

    @State private var userfieldChanges = UserfieldChanges()

    @State private var showPermissions: Bool = false

    @State private var isProcessing: Bool = false
    @State private var isSuccessful: Bool? = nil
    @State private var errorMessage: String? = nil

    var isNewUser: Bool
    var user: GrocyUser?
    /// Opened from one's own account: saving reloads only the current user, because listing all users needs USERS_READ.
    var editsOwnProfile: Bool

    init(isNewUser: Bool, user: GrocyUser? = nil, editsOwnProfile: Bool = false) {
        self.isNewUser = isNewUser
        self.user = user
        self.editsOwnProfile = editsOwnProfile
        _username = State(initialValue: user?.username ?? "")
        _firstName = State(initialValue: user?.firstName ?? "")
        _lastName = State(initialValue: user?.lastName ?? "")
        _isValidUsername = State(initialValue: !(user?.username.isEmpty ?? true))
    }

    /// The users' userfields entity.
    static let userfieldEntity = "users"

    @State private var isValidUsername: Bool
    private func checkUsernameCorrect() -> Bool {
        guard !username.isEmpty else { return false }
        let foundUser = users.first(where: { $0.username == username })
        return foundUser == nil || (!isNewUser && foundUser?.id == user?.id)
    }

    /// A new user needs a password; an edit keeps the current one when both fields stay empty.
    private var isMatchingPassword: Bool {
        password == passwordConfirm && (!isNewUser || !password.isEmpty)
    }

    /// Grocy without its own login (no passwords, no permissions).
    private var isAuthDisabled: Bool {
        systemConfigList.first?.disableAuth == true
    }

    private var savedPictureFileName: String? {
        guard let fileName = user?.pictureFileName, !fileName.isEmpty else { return nil }
        return fileName
    }

    private var hasPicture: Bool {
        newPictureData != nil || (savedPictureFileName != nil && !removesPicture)
    }

    private func updateData() async {
        await grocyVM.requestData(objects: [.userfields])
    }

    private func saveUser() async {
        isProcessing = true
        isSuccessful = nil
        do {
            // The picture first, so the user never points at a file that failed to upload.
            var pictureFileName = removesPicture ? nil : savedPictureFileName
            if let newPictureData {
                let fileName = "\(UUID().uuidString)_\(username.cleanedFileName).jpg"
                try await grocyVM.uploadUserPicture(jpegData: newPictureData, fileName: fileName)
                pictureFileName = fileName
            }

            let userID: Int?
            if isNewUser {
                let userPost = GrocyUserPOST(
                    id: grocyVM.getNewUserID(),
                    username: username,
                    firstName: firstName,
                    lastName: lastName,
                    password: password,
                    pictureFileName: pictureFileName,
                    rowCreatedTimestamp: Date()
                )
                try await grocyVM.postUser(user: userPost)
                GrocyLogger.info("Creating user was successful.")
                userID = try await grocyVM.userID(username: username)
            } else if let user {
                let userPost = GrocyUserPOST(
                    id: user.id,
                    username: username,
                    firstName: firstName,
                    lastName: lastName,
                    password: password,
                    pictureFileName: pictureFileName,
                    rowCreatedTimestamp: user.rowCreatedTimestamp
                )
                try await grocyVM.putUser(id: user.id, user: userPost)
                GrocyLogger.info("Editing user was successful.")
                userID = user.id
            } else {
                userID = nil
            }

            if let savedPictureFileName, savedPictureFileName != pictureFileName {
                do {
                    try await grocyVM.deleteUserPicture(fileName: savedPictureFileName)
                } catch {
                    GrocyLogger.warning("Deleting the replaced user picture failed. \(error)")
                }
            }
            if let userID {
                try await grocyVM.saveUserfields(entity: Self.userfieldEntity, objectID: userID, changes: userfieldChanges)
            }
            await grocyVM.reloadUsers(includingAllUsers: !editsOwnProfile)
            isSuccessful = true
        } catch {
            GrocyLogger.error("Saving user failed. \(error)")
            errorMessage = (error as? APIError)?.displayMessage ?? error.localizedDescription
            isSuccessful = false
        }
        isProcessing = false
    }

    private func loadPicture() async {
        guard let pictureItem else { return }
        do {
            if let data = try await pictureItem.loadTransferable(type: Data.self), let jpeg = uprightJPEG(from: data) {
                newPictureData = jpeg
            }
        } catch {
            GrocyLogger.error("Loading the chosen picture failed. \(error)")
        }
    }

    var body: some View {
        Form {
            if isSuccessful == false, let errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }
            Section(header: Text("Username")) {
                MyTextField(
                    textToEdit: $username,
                    description: "Username",
                    isCorrect: $isValidUsername,
                    leadingIcon: MySymbols.user,
                    emptyMessage: "A username is required",
                    errorMessage: "Username already exists"
                )
                .onChange(of: username) {
                    isValidUsername = checkUsernameCorrect()
                }
                MyTextField(textToEdit: $firstName, description: "First name", isCorrect: .constant(true), leadingIcon: MySymbols.user)
                MyTextField(textToEdit: $lastName, description: "Last name", isCorrect: .constant(true), leadingIcon: MySymbols.user)
            }
            if !isAuthDisabled {
                Section {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    SecureField("Confirm password", text: $passwordConfirm)
                        .textContentType(.newPassword)
                    if password != passwordConfirm, !passwordConfirm.isEmpty {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundStyle(Color(.GrocyColors.grocyRed))
                    }
                } header: {
                    Text("Password")
                } footer: {
                    if !isNewUser {
                        Text("Leave empty to keep the current password.")
                    }
                }
            }
            pictureSection
            UserfieldsSection(entity: Self.userfieldEntity, objectID: user?.id, changes: $userfieldChanges)
            if let user, !isNewUser, !isAuthDisabled, grocyVM.isCurrentUserAdmin == true {
                Section {
                    Button {
                        showPermissions = true
                    } label: {
                        Label("Configure user permissions", systemImage: MySymbols.permissions)
                    }
                    .sheet(isPresented: $showPermissions) {
                        NavigationStack {
                            UserPermissionsView(user: user)
                        }
                        #if os(macOS)
                            .frame(minWidth: Sizes.popoverFormSize, minHeight: Sizes.popoverFormSize)
                        #endif
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isNewUser ? "Create user" : "Edit user")
        .task {
            await updateData()
        }
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(
                    role: .confirm,
                    action: {
                        Task {
                            await saveUser()
                        }
                    }
                )
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidUsername || (!isAuthDisabled && !isMatchingPassword) || isProcessing)
            }
        })
        .onChange(of: pictureItem) {
            Task {
                await loadPicture()
            }
        }
        .onChange(of: isSuccessful) {
            if isSuccessful == true {
                dismiss()
            }
        }
        .sensoryFeedback(.success, trigger: isSuccessful == true)
        .sensoryFeedback(.error, trigger: isSuccessful == false)
    }

    private var pictureSection: some View {
        Section {
            HStack {
                Spacer()
                if let newPictureData, let image = Image(data: newPictureData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: Sizes.userPicture, height: Sizes.userPicture)
                        .clipShape(.circle)
                        .accessibilityHidden(true)
                } else {
                    UserAvatarView(pictureFileName: removesPicture ? nil : savedPictureFileName, size: Sizes.userPicture)
                }
                Spacer()
            }
            PhotosPicker(selection: $pictureItem, matching: .images) {
                Label("Select picture from gallery", systemImage: MySymbols.gallery)
            }
            if hasPicture {
                // The destructive role colors the button, instead of a hard-coded red label.
                Button(role: .destructive) {
                    newPictureData = nil
                    pictureItem = nil
                    removesPicture = true
                } label: {
                    Label("Delete picture", systemImage: MySymbols.delete)
                }
            }
        } header: {
            Text("Picture")
        } footer: {
            if removesPicture, savedPictureFileName != nil, newPictureData == nil {
                Text("The current picture will be deleted on save")
            }
        }
    }
}

#Preview("Create", traits: .previewData) {
    NavigationStack {
        UserFormView(isNewUser: true)
    }
}

#Preview("Edit", traits: .previewData) {
    NavigationStack {
        UserFormView(isNewUser: false, user: GrocyUser(id: 1, username: "demo", firstName: "Demo", lastName: "User", displayName: "Demo User"))
    }
}
