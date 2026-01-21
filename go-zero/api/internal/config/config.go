package config

import (
	"github.com/jinguoxing/idrm-go-base/telemetry"
	"github.com/zeromicro/go-zero/rest"
)

type Config struct {
	rest.RestConf

	// Telemetry 配置
	Telemetry telemetry.Config

	// 数据库配置
	DB struct {
		Default struct {
			Host              string
			Port              int
			Database          string
			Username          string
			Password          string
			Charset           string
			MaxIdleConns      int
			MaxOpenConns      int
			ConnMaxLifetime   int
			ConnMaxIdleTime   int
			LogLevel          string
			SlowThreshold     int64
			SkipDefaultTxn    bool
			PrepareStmt       bool
			SingularTable     bool
			DisableForeignKey bool
		}
	}

	// Redis 配置
	Redis struct {
		Host     string
		Port     int
		DB       int
		Password string
	}

	// 认证配置
	Auth struct {
		AccessSecret string
		AccessExpire int64
	}

	// RPC 客户端配置 (如果有)
	// UserRpc zrpc.RpcClientConf

	// Swagger 配置
	Swagger struct {
		Enabled bool
		Path    string
	}
}
