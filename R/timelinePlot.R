
#' Timeline plot
#'
#' @description
#' `timelinePlot()` is used to generate a patient timeline plot to view longitudinal data.
#'
#' @param data Data frame object with columns detailing the specific event, event category, event start time and event stop time
#' @param event_col Column name of specific event name column. Defaults to first column.
#' @param event_type_col Column name of event category column. Defaults to second column.
#' @param start_col Column name of event start time column. Defaults to third column.
#' @param stop_col Column name of event stop time column. Defaults to fourth column.
#' @param title Desired plot title.
#' @param title_font Size of title font.
#' @param x_font Size of font on the x-axis.
#' @param y_font Size of font on the y-axis
#' @param na.rm Boolean. If TRUE, events with incomplete time data will be removed.
#'
#' @return plot
#' @export
#'
#' @examples
#' df <- data.frame(Event = c("Diagnosis","Death","Medication: Carboplatin","Medication: Carboplatin",
#'                            "Imaging: Diagnostic","Imaging: Surveillance","Surgery Biopsy: Peritoneum, NOS"),
#'                  EventType = c("Clinical Time Point","Clinical Time Point","Medication",
#'                                "Medication","Imaging","Imaging","Surgery Biopsy"),
#'                  AgeAtEventStart = c(69.085,71.507,69.189,69.441,69.142,70.134,69.085),
#'                  AgeAtEventStop = c(69.085,71.507,69.326,69.647,69.142,70.134,69.085))
#' timelinePlot(data = df, event_col = "Event", event_type_col = "EventType",
#'              start_col = "AgeAtEventStart", stop_col = "AgeAtEventStop")
#'


timelinePlot <- function(data = NULL,event_col = NULL, event_type_col = NULL, start_col = NULL, stop_col = NULL,
                         title = "Timeline Plot", title_font = 16, x_font = 14, y_font = 14, na.rm = TRUE) {

  if (is.null(data)) stop("Must provide event data")
  if (is.null(event_col)) event_col <- colnames(data)[1]
  if (is.null(event_type_col)) event_type_col <- colnames(data)[2]
  if (is.null(start_col)) start_col <- colnames(data)[3]
  if (is.null(stop_col)) stop_col <- colnames(data)[4]
  if (!is.numeric(data[,start_col])) stop("Event start time must be numeric")
  if (!is.numeric(data[,stop_col])) stop("Event stop time must be numeric")

  if (na.rm) {
    data <- data[which(!is.na(data[,start_col]) | !is.na(data[,stop_col])),] # remove data with incomplete time
  }

  # Get index of data to combine similar data points
  data$EventTempCol <- data[,event_col]
  data[,event_col] <- paste0(data[,event_type_col],": ",data[,event_col])
  data$index <- as.numeric(factor(data[,event_col]))
  data[,event_col] <- data$EventTempCol
  data <- data[,grep("EventTempCol",colnames(data), value = T, invert = T)]

  # Get x axis min and max
  allAges <- c(data[,start_col],data[,stop_col])

  plot2 <- ggplot2::ggplot(data, ggplot2::aes(x=!!ggplot2::sym(start_col), y=index, label = !!ggplot2::sym(event_col), color = !!ggplot2::sym(event_type_col))) +
    ## Add end time points
    ggplot2::geom_point(ggplot2::aes(x=!!ggplot2::sym(stop_col), y=index),size=4)+
    ## draw lines - inherits start time point x,y
    ggplot2::geom_segment(ggplot2::aes(xend = !!ggplot2::sym(stop_col), yend = index), linewidth = 2, lineend = "butt") +
    ## x and y labels
    ggplot2::xlab("Age (Years)") +
    ggplot2::ylab('') +
    ggplot2::theme_minimal() +
    ## adjust x & y axis to accommodate the event lables
    ggplot2::scale_y_continuous(breaks=unique(data$index), # each line break from the index column
                       labels = stringr::str_wrap(unique(data[,event_col]), width = 60), # event label
                       trans = "reverse") +
    ggplot2::scale_x_continuous(limits=c(min(allAges), max(allAges)))

  g <- ggplot2::ggplot_build(plot2)
  YlabCols <- g[["data"]][[1]][["colour"]]
  yLabs <- g[["data"]][[1]][["label"]]
  newCols_df <- data.frame(Labs = yLabs,
                           cols = YlabCols)
  newCols_df_uniq <- unique(newCols_df)

  plot2 <- plot2 +
    ## adjust font size and face and legend position
    ggplot2::theme(plot.title = ggplot2::element_text(size=title_font,face="bold"),
          legend.position = "none",
          axis.text.x = ggplot2::element_text(size=x_font),
          axis.text.y = ggtext::element_markdown(size=y_font, colour = newCols_df_uniq$cols),
          axis.title.x = ggplot2::element_text(size=x_font,face="bold"),
          axis.title.y = ggplot2::element_text(size=y_font,face="bold"),
          plot.margin = ggplot2::margin(0, 2, 0, 0, "cm")
    ) +
    ## add title
    ggplot2::ggtitle(title)
  return(plot2)

}
