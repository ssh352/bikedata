context ("download data")

require (testthat)

test_that ('no city', {
               expect_error (dl_bikedata (), 'city must be specified')
})

# download can't really be tested, so this just tests that it does **NOT**
# download if all files already exist

# code copied from get_aws_bike_files 
get_fake_trip_files <- function (bucket)
{
    aws_url <- sprintf ("https://%s.s3.amazonaws.com", bucket)

    doc <- httr::content (httr::GET (aws_url), encoding = 'UTF-8')
    nodes <- xml2::xml_children (doc)
    # NOTE: xml2::xml_find_all (doc, ".//Key") should work here but doesn't, so
    # this manually does what that would do
    files <- lapply (nodes, function (i)
                     if (grepl ('zip|csv', i))
                         strsplit (strsplit (as.character (i),
                                             "<Key>") [[1]] [2],
                                   "</Key>") [[1]] [1] )
    files <- file.path (tempdir (), unlist (files))
    if (bucket == 'tripdata')
        files <- files [2:length (files)]
    for (f in files)
        write ('a', file = f)

    return (files)
}

dates <- c (16, 201604:201608, "2016/04:2016/08",
            "201604:201608", "16 apr:aug", "2016-04:2016-08")

test_that ('dl_bikedata nyc', {
               files <- get_fake_trip_files (bucket = 'tripdata')
               expect_message (dl_bikedata (city = 'nyc',
                                            data_dir = tempdir ()),
                               'All data files already exist')
               for (d in dates)
                   expect_message (dl_bikedata (city = 'nyc',
                                                data_dir = tempdir (),
                                                dates = d),
                                   'All data files already exist')
               chk <- tryCatch (file.remove (files),
                                warning = function (w) NULL,
                                error = function (e) NULL)
                         })

test_that ('dl_bikedata dc', {
               files <- get_fake_trip_files (bucket = "capitalbikeshare-data")
               expect_message (dl_bikedata (city = 'dc',
                                            data_dir = tempdir ()),
                               'All data files already exist')
               for (d in dates)
                   expect_message (dl_bikedata (city = 'dc',
                                                data_dir = tempdir (),
                                                dates = d),
                                   'All data files already exist')
               chk <- tryCatch (file.remove (files),
                                warning = function (w) NULL,
                                error = function (e) NULL)
                         })

test_that ('dl_bikedata boston', {
               files <- get_fake_trip_files (bucket = "hubway-data")
               expect_message (dl_bikedata (city = 'boston',
                                            data_dir = tempdir ()),
                               'All data files already exist')
               for (d in dates)
                   expect_message (dl_bikedata (city = 'boston',
                                                data_dir = tempdir (),
                                                dates = d),
                                   'All data files already exist')
               chk <- tryCatch (file.remove (files),
                                warning = function (w) NULL,
                                error = function (e) NULL)
                         })

testthat::skip_on_cran ()

test_that ('dl_bikedata la', {
               # These files change names, so this test first GETs the names of
               # current files
               dl_files <- get_bike_files (city = "la")
               dates <- "2016"
               indx <- grep (dates, basename (dl_files))
               files <- file.path (tempdir (), basename (dl_files [indx]))
               for (f in files) write ('a', file = f)
               expect_message (dl_bikedata (city = 'la',
                                            data_dir = tempdir (),
                                            dates = 2016),
                               'All data files already exist')
               chk <- tryCatch (file.remove (files),
                                warning = function (w) NULL,
                                error = function (e) NULL)
                         })

test_that ('dl_bikedata chicago', {
               host <- "https://www.divvybikes.com/system-data"
               nodes <- httr::content (httr::GET (host),
                                       encoding = 'UTF-8') %>%
                                       xml2::xml_find_all (., ".//aside") %>%
                                       xml2::xml_find_all (., ".//a")
               files <- unique (basename (xml2::xml_attr (nodes, "href")))
               files <- file.path (tempdir (), files)
               for (f in files) write ('a', file = f)
               expect_message (dl_bikedata (city = 'chicago',
                                            data_dir = tempdir ()),
                               'All data files already exist')
               for (d in dates)
                   expect_message (dl_bikedata (city = 'chicago',
                                                data_dir = tempdir (),
                                                dates = d),
                                   'All data files already exist')
               chk <- tryCatch (file.remove (files),
                                warning = function (w) NULL,
                                error = function (e) NULL)
                         })

# test_all used to switch off tests on CRAN
test_all <- (identical (Sys.getenv ("MPADGE_LOCAL"), "true") |
             identical (Sys.getenv ("TRAVIS"), "true") |
             identical (Sys.getenv ("APPVEYOR"), "True"))

# extra tests for other cities
test_that ('download london data (for real!)', {
               if (test_all)
               {
                   expect_message (f <- dl_bikedata (city = "lo", dates = 201501))
                   expect_equal (length (f), 2)
               }
})
