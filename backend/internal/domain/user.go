package domain

import "time"

// Role represents the role entity
type Role struct {
	ID        uint   `json:"id_role" gorm:"primaryKey;column:id_role;autoIncrement"`
	NamaRole  string `json:"nama_role" gorm:"unique;not null;column:nama_role;type:varchar(30)"`
	Prioritas int    `json:"prioritas" gorm:"column:prioritas;not null;type:smallint"`
}

// User represents the user entity
type User struct {
	ID              uint      `json:"id_user" gorm:"primaryKey;column:id_user;autoIncrement"`
	RoleID          uint      `json:"id_role" gorm:"column:id_role;type:smallint"`
	Role            Role      `json:"role" gorm:"foreignKey:RoleID;references:ID"`
	Nama            string      `json:"nama" gorm:"not null;column:nama;type:varchar(100)"`
	Nim             string      `json:"nim" gorm:"column:nim;type:varchar(20)"`
	Email           string      `json:"email" gorm:"uniqueIndex;not null;column:email;type:varchar(100)"`
	PasswordHash    string      `json:"-" gorm:"not null;column:password_hash;type:text"`
	ProfileImageURL string      `json:"profile_image_url" gorm:"column:profile_image_url;type:text"`
	Status          string      `json:"status" gorm:"column:status;type:varchar(20);default:'active'"`
	CreatedAt       time.Time   `json:"created_at" gorm:"column:created_at;autoCreateTime"`
	Kendaraans      []Kendaraan `json:"kendaraans" gorm:"foreignKey:UserID"`
}

// UserRepository interface defines the methods that any repository must implement
type UserRepository interface {
	Create(user *User) error
	FindByEmail(email string) (*User, error)
	FindByID(id uint) (*User, error)
	UpdatePassword(userID uint, newPasswordHash string) error
	UpdateProfileImageURL(userID uint, imageURL string) error
}

// UserUsecase interface defines the standard business logic methods
type UserUsecase interface {
	Register(nama, nim, email, password, platNomor, jenisKendaraan string) (*User, error)
	Login(email, password string) (string, *User, error)
	ChangePassword(userID uint, currentPassword, newPassword string) error
	GetProfile(userID uint) (*User, error)
	UpdateProfileImageURL(userID uint, imageURL string) error
}
