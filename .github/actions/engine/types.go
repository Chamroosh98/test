package main

type InlineKeyboardButton struct {
	Text string `json:"text"`
	URL  string `json:"url"`
}

type InlineKeyboardMarkup struct {
	InlineKeyboard [][]InlineKeyboardButton `json:"inline_keyboard"`
}

type TelegramMessage struct {
	ChatID                string                 `json:"chat_id"`
	Text                  string                 `json:"text"`
	ParseMode             string                 `json:"parse_mode"`
	ReplyMarkup           InlineKeyboardMarkup   `json:"reply_markup"`
	DisableWebPagePreview bool                   `json:"disable_web_page_preview"`
}

type FeedConfig struct {
	Name    string   `json:"name"`
	BaseURL string   `json:"base_url"`
	Feeds   []string `json:"feeds"`
}

type ArchConfig struct {
	Architectures []FeedConfig `json:"architectures"`
}