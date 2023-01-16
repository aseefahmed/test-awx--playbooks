USE [master]
GO
ALTER DATABASE [model] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [model] SET AUTO_CREATE_STATISTICS ON
GO
ALTER DATABASE [model] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [model] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [model] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [model] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [model] SET READ_WRITE 
GO
ALTER DATABASE model
    MODIFY FILE
    (NAME = modeldev,
    FILEGROWTH = 10%);
GO
ALTER DATABASE model
    MODIFY FILE
    (NAME = modellog,
	FILEGROWTH = 10%);